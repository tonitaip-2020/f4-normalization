#!/usr/bin/env python3
"""Run one timestamped PostgreSQL benchmark measurement.

The script is designed for a single-node PostgreSQL experiment:
- one schema condition per invocation;
- optional fixed warm-up, then a measured pgbench interval (default: 3600 s);
- pg_stat_io snapshots, iostat, vmstat, environment snapshots, and pgbench logs;
- JSON manifest per run plus a root-level CSV and JSONL ledger.

When NETIO endpoint and basic-auth credentials are supplied, the runner polls
netio.json for one configured socket and stores raw samples plus Wh summaries.
"""
from __future__ import annotations

import argparse
import base64
import csv
import datetime as dt
import json
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import subprocess
import sys
import time
import threading
from urllib.error import URLError
from urllib.request import Request, urlopen
import uuid
from typing import Any, Callable

SCHEMAS = ("baseline", "1nf", "2nf", "4nf")
SCALES = ("imdb-1", "imdb-0.1")
UTC = dt.timezone.utc


def utc_now() -> str:
    return dt.datetime.now(UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def run_capture(command: list[str], output: Path, *, check: bool = True,
                on_output_line: Callable[[str], None] | None = None,
                env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    """Run a command, persist combined output, and optionally handle lines as they arrive."""
    if on_output_line is not None:
        process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   bufsize=1, env=env)
        try:
            with output.open("w", encoding="utf-8") as handle:
                assert process.stdout is not None
                for line in process.stdout:
                    handle.write(line)
                    handle.flush()
                    on_output_line(line)
            returncode = process.wait()
        except KeyboardInterrupt:
            if process.poll() is None:
                process.send_signal(signal.SIGINT)
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
            raise
        result = subprocess.CompletedProcess(command, returncode, "")
        if check and result.returncode:
            raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(command)}; see {output}")
        return result
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
    output.write_text(result.stdout, encoding="utf-8")
    if check and result.returncode:
        raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(command)}; see {output}")
    return result


def version(command: list[str]) -> str:
    try:
        return subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              timeout=15).stdout.strip()
    except Exception as exc:
        return f"unavailable: {exc}"


def psql_command(args: argparse.Namespace, sql: str) -> list[str]:
    return [args.psql, "-X", "-v", "ON_ERROR_STOP=1", "-d", args.database, "-c", sql]


def psql_snapshot(args: argparse.Namespace, run_dir: Path, name: str, sql: str) -> None:
    run_capture(psql_command(args, sql), run_dir / name)


def shell_hook(command: str | None, event: str, run_dir: Path, manifest: dict[str, Any]) -> None:
    if not command:
        return
    rendered = command.format(run_dir=str(run_dir), event=event, run_id=manifest["run_id"])
    env = os.environ | {
        "BENCH_RUN_DIR": str(run_dir),
        "BENCH_EVENT": event,
        "BENCH_RUN_ID": manifest["run_id"],
    }
    result = subprocess.run(rendered, shell=True, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, env=env)
    (run_dir / f"hook_{event}.txt").write_text(result.stdout, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(f"NETIO hook '{event}' failed; see hook_{event}.txt")


def start_monitor(command: list[str], output: Path) -> subprocess.Popen[str]:
    handle = output.open("w", encoding="utf-8")
    process = subprocess.Popen(command, stdout=handle, stderr=subprocess.STDOUT,
                               text=True, start_new_session=True)
    process._benchmark_handle = handle  # type: ignore[attr-defined]
    return process


def stop_monitor(process: subprocess.Popen[str]) -> None:
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
    process._benchmark_handle.close()  # type: ignore[attr-defined]


def parse_pgbench(text: str) -> dict[str, float | int | None]:
    transactions = re.search(r"number of transactions actually processed:\s+(\d+)", text)
    tps = re.findall(r"tps\s*=\s*([0-9.]+)", text)
    latency = re.findall(r"latency average\s*=\s*([0-9.]+)", text)
    failures = re.search(r"number of failed transactions:\s+(\d+)", text)
    successful = int(transactions.group(1)) if transactions else None
    failed = int(failures.group(1)) if failures else None
    attempted = successful + failed if successful is not None and failed is not None else None
    return {
        "transactions": successful,
        "failed_transactions": failed,
        "attempted_transactions": attempted,
        "failed_transactions_pct": (100.0 * failed / attempted) if attempted else (0.0 if attempted == 0 else None),
        "tps": float(tps[-1]) if tps else None,
        "latency_ms": float(latency[-1]) if latency else None,
    }


class NetioCollector:
    """Poll NETIO netio.json for one socket and persist raw observations."""
    def __init__(self, args: argparse.Namespace, run_dir: Path, *, artifact_prefix: str = "") -> None:
        self.url = args.netio_url
        self.user = args.netio_user
        self.password = args.netio_password
        self.socket_id = args.netio_socket_id
        self.interval = args.netio_interval
        self.timeout = args.netio_timeout
        self.run_dir = run_dir
        self.artifact_prefix = artifact_prefix
        self.samples: list[dict[str, Any]] = []
        self.errors: list[str] = []
        self.lock = threading.Lock()
        self.stop_event = threading.Event()
        self.thread: threading.Thread | None = None

    @staticmethod
    def number(value: Any) -> float | None:
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    def fetch(self) -> dict[str, Any]:
        token = base64.b64encode(f"{self.user}:{self.password}".encode("utf-8")).decode("ascii")
        request = Request(self.url, headers={"Authorization": f"Basic {token}", "Accept": "application/json"})
        with urlopen(request, timeout=self.timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def sample(self, *, raise_on_error: bool = False) -> None:
        captured = utc_now()
        epoch = time.time()
        try:
            data = self.fetch()
            outputs = data.get("Outputs", [])
            output = next((x for x in outputs if int(x.get("ID", -1)) == self.socket_id), None)
            if output is None:
                raise RuntimeError(f"NETIO socket ID {self.socket_id} not found in Outputs")
            agent = data.get("Agent", {})
            global_measure = data.get("GlobalMeasure", {})
            row = {
                "captured_utc": captured,
                "captured_epoch_s": epoch,
                "netio_device_time": agent.get("Time"),
                "netio_device_name": agent.get("DeviceName"),
                "socket_id": self.socket_id,
                "socket_state": output.get("State"),
                "socket_load_w": self.number(output.get("Load")),
                "socket_current_ma": self.number(output.get("Current")),
                "socket_energy_wh_counter": self.number(output.get("Energy")),
                "grid_voltage_v": self.number(global_measure.get("Voltage")),
                "grid_frequency_hz": self.number(global_measure.get("Frequency")),
                "grid_total_load_w": self.number(global_measure.get("TotalLoad")),
            }
            with self.lock:
                self.samples.append(row)
        except Exception as exc:
            message = f"{captured}: {exc}"
            with self.lock:
                self.errors.append(message)
            if raise_on_error:
                raise RuntimeError(message) from exc

    def start(self) -> None:
        self.sample(raise_on_error=True)
        self.thread = threading.Thread(target=self._poll, name="netio-poller", daemon=True)
        self.thread.start()

    def live_summary(self) -> dict[str, float | None]:
        """Return the latest load and counter-based energy since this collector started."""
        with self.lock:
            samples = list(self.samples)
        if not samples:
            return {"load_w": None, "energy_wh": None}
        latest = samples[-1]
        counters = [x["socket_energy_wh_counter"] for x in samples
                    if x.get("socket_energy_wh_counter") is not None]
        energy_wh = None
        if len(counters) >= 2 and counters[-1] >= counters[0]:
            energy_wh = counters[-1] - counters[0]
        return {"load_w": latest.get("socket_load_w"), "energy_wh": energy_wh}

    def _poll(self) -> None:
        while not self.stop_event.wait(self.interval):
            self.sample()

    def stop(self) -> dict[str, Any]:
        self.stop_event.set()
        if self.thread:
            self.thread.join(timeout=self.timeout + self.interval + 2)
        self.sample()
        with self.lock:
            samples, errors = list(self.samples), list(self.errors)
        fieldnames = ["captured_utc", "captured_epoch_s", "netio_device_time", "netio_device_name",
                      "socket_id", "socket_state", "socket_load_w", "socket_current_ma",
                      "socket_energy_wh_counter", "grid_voltage_v", "grid_frequency_hz", "grid_total_load_w"]
        with (self.run_dir / f"{self.artifact_prefix}netio_samples.csv").open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader(); writer.writerows(samples)
        (self.run_dir / f"{self.artifact_prefix}netio_errors.txt").write_text(
            "\n".join(errors) + ("\n" if errors else ""), encoding="utf-8")
        summary: dict[str, Any] = {"netio_url": self.url, "netio_socket_id": self.socket_id,
                                   "netio_sample_count": len(samples), "netio_error_count": len(errors)}
        if len(samples) < 2:
            raise RuntimeError("NETIO produced fewer than two samples; energy cannot be computed")
        def integrate(key: str) -> float | None:
            pairs = [(x["captured_epoch_s"], x[key]) for x in samples if x.get(key) is not None]
            if len(pairs) < 2:
                return None
            return sum((a[1] + b[1]) * (b[0] - a[0]) / 2 / 3600 for a, b in zip(pairs, pairs[1:]))
        counters = [x["socket_energy_wh_counter"] for x in samples if x.get("socket_energy_wh_counter") is not None]
        summary["netio_socket_load_integrated_wh"] = integrate("socket_load_w")
        summary["netio_grid_load_integrated_wh"] = integrate("grid_total_load_w")
        if len(counters) >= 2 and counters[-1] >= counters[0]:
            summary["netio_socket_energy_counter_start_wh"] = counters[0]
            summary["netio_socket_energy_counter_end_wh"] = counters[-1]
            summary["netio_socket_energy_counter_delta_wh"] = counters[-1] - counters[0]
        return summary


def append_ledger(root: Path, row: dict[str, Any]) -> None:
    jsonl = root / "run_ledger.jsonl"
    with jsonl.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True) + "\n")
    csv_path = root / "run_ledger.csv"
    fields = ["run_id", "status", "started_utc", "ended_utc", "schema", "scale", "ram_gb",
              "database", "duration_s", "warmup_s", "clients", "jobs", "transactions",
              "tps", "latency_ms", "failed_transactions", "attempted_transactions",
               "failed_transactions_pct", "transaction_timeout_s", "run_dir"]
    exists = csv_path.exists()
    with csv_path.open("a", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        if not exists:
            writer.writeheader()
        writer.writerow({k: row.get(k) for k in fields})


def snapshot_environment(args: argparse.Namespace, run_dir: Path) -> None:
    redacted = list(sys.argv)
    for index, token in enumerate(redacted[:-1]):
        if token == "--netio-password":
            redacted[index + 1] = "***REDACTED***"
        elif token.startswith("--netio-password="):
            redacted[index] = "--netio-password=***REDACTED***"
    (run_dir / "command.txt").write_text(" ".join(map(shlex_quote, redacted)) + "\n", encoding="utf-8")
    (run_dir / "tool_versions.json").write_text(json.dumps({
        "python": sys.version,
        "pgbench": version([args.pgbench, "--version"]),
        "psql": version([args.psql, "--version"]),
        "iostat": version([args.iostat, "--version"]),
        "vmstat": version([args.vmstat, "--version"]),
    }, indent=2) + "\n", encoding="utf-8")
    (run_dir / "host_platform.json").write_text(json.dumps({
        "platform": platform.platform(),
        "hostname": platform.node(),
        "kernel": platform.release(),
    }, indent=2) + "\n", encoding="utf-8")
    for name, command in {
        "meminfo_before.txt": ["cat", "/proc/meminfo"],
        "free_before.txt": ["free", "-h"],
        "lscpu.txt": ["lscpu"],
        "lsblk.txt": ["lsblk", "-o", "NAME,MODEL,SIZE,TYPE,MOUNTPOINTS"],
    }.items():
        if shutil.which(command[0]):
            run_capture(command, run_dir / name, check=False)


def shlex_quote(value: str) -> str:
    if re.fullmatch(r"[A-Za-z0-9_./:=+-]+", value):
        return value
    return "'" + value.replace("'", "'\"'\"'") + "'"


def pgbench_command(args: argparse.Namespace, duration: int, *, progress: bool = False) -> list[str]:
    """Build a pgbench command that chooses one supplied script per transaction."""
    command = [args.pgbench, "-c", str(args.clients), "-j", str(args.jobs),
               "-T", str(duration), "-M", args.query_mode, "-n"]
    if progress and args.progress_seconds:
        command.extend(["-P", str(args.progress_seconds)])
    for workload in args.workload:
        command.extend(["-f", str(workload)])
    # PostgreSQL 16 uses -d for pgbench debug output, not a database name.
    # Passing the database positionally is portable across supported versions.
    command.append(args.database)
    return command


def live_progress_reporter(phase: str, netio: NetioCollector | None) -> Callable[[str], None]:
    """Echo pgbench progress plus the latest wall-power reading to the terminal."""
    def report(line: str) -> None:
        if not line.lstrip().startswith("progress:"):
            return
        message = f"[{utc_now()}] {phase}: {line.strip()}"
        if netio:
            meter = netio.live_summary()
            details: list[str] = []
            if meter["load_w"] is not None:
                details.append(f"wall={meter['load_w']:.1f} W")
            if meter["energy_wh"] is not None:
                details.append(f"energy={meter['energy_wh']:.3f} Wh since {phase.lower()} start")
            if details:
                message += " | " + "; ".join(details)
        print(message, flush=True)
    return report


def resolve_workloads(args: argparse.Namespace, parser: argparse.ArgumentParser) -> list[Path]:
    """Resolve an explicit list or the seven schema-specific scripts under a workload root."""
    if args.workload_root:
        schema_dir = args.workload_root / args.schema
        expected = [schema_dir / f"q{number}.sql" for number in range(1, 8)]
        missing = [str(path) for path in expected if not path.is_file()]
        if missing:
            parser.error("schema workload directory must contain q1.sql through q7.sql; missing: "
                         + ", ".join(missing))
        return expected
    assert args.workload is not None
    return args.workload


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("schema", choices=SCHEMAS, help="schema under test")
    parser.add_argument("--scale", choices=SCALES, required=True, help="IMDb scale under test")
    parser.add_argument("--ram-gb", type=int, choices=(16, 32, 64), required=True,
                        help="recorded RAM regime; enforce the memory limit outside this runner")
    parser.add_argument("--database", required=True, help="PostgreSQL database name for this schema condition")
    workload_source = parser.add_mutually_exclusive_group(required=True)
    workload_source.add_argument("--workload", type=Path, action="append",
                                 help="custom pgbench SQL script; repeat once per transaction type (chosen equally)")
    workload_source.add_argument("--workload-root", type=Path,
                                 help="directory containing baseline/, 1nf/, 2nf/, and 4nf/; each has q1.sql–q7.sql")
    parser.add_argument("--output-root", type=Path, default=Path.home() / "imdb-benchmark-results")
    parser.add_argument("--duration", type=int, default=3600, help="measured pgbench duration in seconds")
    parser.add_argument("--warmup", type=int, default=1200, help="unmeasured warm-up duration in seconds")
    parser.add_argument("--clients", type=int, default=48)
    parser.add_argument("--jobs", type=int, default=12)
    parser.add_argument("--transaction-timeout", type=float, default=10.0,
                        help="per-statement timeout in seconds; one SQL statement per transaction recommended (0 disables; default: 10)")
    parser.add_argument("--query-mode", choices=("simple", "extended", "prepared"), default="simple",
                        help="pgbench protocol (default: simple; use consistently across all runs)")
    parser.add_argument("--device", default="nvme0n1", help="Linux block device for iostat, e.g. nvme0n1")
    parser.add_argument("--sample-seconds", type=int, default=1)
    parser.add_argument("--progress-seconds", type=int, default=120,
                        help="print and save pgbench progress every N seconds in both phases (0 disables; default: 120)")
    parser.add_argument("--pgbench", default="pgbench")
    parser.add_argument("--psql", default="psql")
    parser.add_argument("--iostat", default="iostat")
    parser.add_argument("--vmstat", default="vmstat")
    parser.add_argument("--netio-start-command", help="optional shell hook; {run_dir}, {event}, {run_id} available")
    parser.add_argument("--netio-stop-command", help="optional shell hook; {run_dir}, {event}, {run_id} available")
    parser.add_argument("--netio-url", default=os.getenv("NETIO_URL"),
                        help="NETIO JSON endpoint, e.g. http://192.168.1.78/netio.json")
    parser.add_argument("--netio-user", default=os.getenv("NETIO_USER"), help="NETIO basic-auth user")
    parser.add_argument("--netio-password", default=os.getenv("NETIO_PASSWORD"), help="NETIO basic-auth password")
    parser.add_argument("--netio-socket-id", type=int, default=1, help="metered NETIO socket ID")
    parser.add_argument("--netio-interval", type=float, default=2.0, help="NETIO polling interval in seconds")
    parser.add_argument("--netio-timeout", type=float, default=5.0, help="NETIO HTTP timeout in seconds")
    parser.add_argument("--no-reset-pg-stat-io", action="store_true",
                        help="do not call pg_stat_reset_shared('io')")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    args.workload = resolve_workloads(args, parser)
    # PGOPTIONS applies to pgbench connections without modifying database-wide settings.
    pgbench_env = os.environ.copy()
    if args.transaction_timeout > 0:
        timeout_ms = round(args.transaction_timeout * 1000)
        if timeout_ms < 1:
            parser.error("--transaction-timeout must be at least 0.001 seconds, or 0 to disable")
        pgbench_env["PGOPTIONS"] = (pgbench_env.get("PGOPTIONS", "")
                                   + f" -c statement_timeout={timeout_ms}ms").strip()

    if (args.duration <= 0 or args.warmup < 0 or args.clients <= 0 or args.jobs <= 0
            or args.sample_seconds <= 0 or args.progress_seconds < 0
            or args.transaction_timeout < 0):
        parser.error("duration, clients, jobs, and sample-seconds must be positive; warmup and progress-seconds may be zero")
    if args.netio_url and (not args.netio_user or not args.netio_password):
        parser.error("--netio-url requires --netio-user and --netio-password, or NETIO_USER/NETIO_PASSWORD")
    if args.netio_interval <= 0 or args.netio_timeout <= 0:
        parser.error("NETIO interval and timeout must be positive")
    for workload in args.workload:
        if not workload.is_file():
            parser.error(f"workload file does not exist: {workload}")
    for executable in (args.pgbench, args.psql, args.iostat, args.vmstat):
        if not shutil.which(executable):
            parser.error(f"required executable not found in PATH: {executable}")

    if args.dry_run:
        print(json.dumps({
            "pgbench": pgbench_command(args, args.duration, progress=True),
            "pgoptions": pgbench_env.get("PGOPTIONS", ""),
            "iostat": [args.iostat, "-xmd", "-y", str(args.sample_seconds), args.device],
            "vmstat": [args.vmstat, str(args.sample_seconds)],
        }, indent=2))
        return 0

    args.output_root.mkdir(parents=True, exist_ok=True)
    started = utc_now()
    stamp = started.replace(":", "").replace("-", "").replace(".", "").replace("Z", "Z")
    run_id = f"{stamp}--{args.scale}--{args.schema}--ram{args.ram_gb}g--{uuid.uuid4().hex[:8]}"
    run_dir = args.output_root / run_id
    run_dir.mkdir()
    manifest: dict[str, Any] = {
        "run_id": run_id, "status": "running", "started_utc": started,
        "schema": args.schema, "scale": args.scale, "ram_gb": args.ram_gb,
        "database": args.database, "duration_s": args.duration, "warmup_s": args.warmup,
        "clients": args.clients, "jobs": args.jobs, "query_mode": args.query_mode, "device": args.device,
        "transaction_timeout_s": args.transaction_timeout,
        "pgbench_progress_seconds": args.progress_seconds,
        "workload_root": str(args.workload_root.resolve()) if args.workload_root else None,
        "workloads": [str(workload.resolve()) for workload in args.workload], "run_dir": str(run_dir),
    }
    monitors: list[subprocess.Popen[str]] = []
    netio: NetioCollector | None = None
    warmup_netio: NetioCollector | None = None
    try:
        snapshot_environment(args, run_dir)
        psql_snapshot(args, run_dir, "postgres_version.txt", "SELECT version();")
        psql_snapshot(args, run_dir, "postgres_settings.txt",
                      "SHOW shared_buffers; SHOW work_mem; SHOW effective_cache_size; SHOW track_io_timing;")
        if args.warmup:
            if args.netio_url:
                warmup_netio = NetioCollector(args, run_dir, artifact_prefix="warmup_")
                warmup_netio.start()
            manifest["warmup_started_utc"] = utc_now()
            print(f"[{manifest['warmup_started_utc']}] Warm-up starting: {args.warmup} s, "
                  f"{args.clients} clients, {args.jobs} jobs.", flush=True)
            warmup_cmd = pgbench_command(args, args.warmup, progress=True)
            run_capture(warmup_cmd, run_dir / "pgbench_warmup.txt",
                        on_output_line=live_progress_reporter("Warm-up", warmup_netio), env=pgbench_env)
            manifest["warmup_ended_utc"] = utc_now()
            if warmup_netio:
                manifest["warmup_netio"] = warmup_netio.stop()
                warmup_netio = None
            print(f"[{manifest['warmup_ended_utc']}] Warm-up complete. "
                  "Resetting I/O statistics and starting measured run.", flush=True)

        if not args.no_reset_pg_stat_io:
            psql_snapshot(args, run_dir, "pg_stat_io_reset.txt", "SELECT pg_stat_reset_shared('io');")
        psql_snapshot(args, run_dir, "pg_stat_io_before.txt", "SELECT now() AS captured_utc, * FROM pg_stat_io;")
        monitors = [
            start_monitor([args.iostat, "-xmd", "-y", str(args.sample_seconds), args.device], run_dir / "iostat.txt"),
            start_monitor([args.vmstat, str(args.sample_seconds)], run_dir / "vmstat.txt"),
        ]
        if args.netio_url:
            netio = NetioCollector(args, run_dir)
            netio.start()
        manifest["measurement_started_utc"] = utc_now()
        shell_hook(args.netio_start_command, "start", run_dir, manifest)
        print(f"[{manifest['measurement_started_utc']}] Measured run starting: {args.duration} s. "
              "Wall-energy counter reset point captured.", flush=True)
        measured_cmd = pgbench_command(args, args.duration, progress=True)
        result = run_capture(measured_cmd, run_dir / "pgbench_measured.txt",
                             on_output_line=live_progress_reporter("Measured run", netio), env=pgbench_env)
        manifest["pgbench_returncode"] = result.returncode
        shell_hook(args.netio_stop_command, "stop", run_dir, manifest)
        if netio:
            manifest.update(netio.stop())
        manifest["measurement_ended_utc"] = utc_now()
        print(f"[{manifest['measurement_ended_utc']}] Measured run complete. Collecting final snapshots.", flush=True)
        psql_snapshot(args, run_dir, "pg_stat_io_after.txt", "SELECT now() AS captured_utc, * FROM pg_stat_io;")
        if shutil.which("free"):
            run_capture(["free", "-h"], run_dir / "free_after.txt", check=False)
        if shutil.which("dmesg"):
            run_capture(["dmesg", "-T"], run_dir / "dmesg_after.txt", check=False)
        manifest.update(parse_pgbench((run_dir / "pgbench_measured.txt").read_text(encoding="utf-8")))
        transactions = manifest.get("transactions")
        if isinstance(transactions, int) and transactions > 0:
            for energy_key, label in [
                ("netio_socket_energy_counter_delta_wh", "netio_socket_counter_mwh_per_transaction"),
                ("netio_socket_load_integrated_wh", "netio_socket_integrated_mwh_per_transaction"),
                ("netio_grid_load_integrated_wh", "netio_grid_integrated_mwh_per_transaction"),
            ]:
                energy_wh = manifest.get(energy_key)
                if isinstance(energy_wh, (int, float)):
                    manifest[label] = energy_wh * 1000 / transactions
        if manifest.get("failed_transactions") is None:
            raise RuntimeError("pgbench did not report failed transaction counts; verify pgbench 19 output")
        manifest["status"] = "succeeded"
        return_code = 0
    except KeyboardInterrupt:
        manifest["status"] = "interrupted"
        manifest["error"] = "interrupted by user"
        (run_dir / "failure.txt").write_text("interrupted by user\n", encoding="utf-8")
        print(f"[{utc_now()}] Run interrupted; partial artefacts are being finalized and must not be analysed.",
              flush=True)
        return_code = 130
    except Exception as exc:
        manifest["status"] = "failed"
        manifest["error"] = str(exc)
        (run_dir / "failure.txt").write_text(str(exc) + "\n", encoding="utf-8")
        try:
            shell_hook(args.netio_stop_command, "stop_after_failure", run_dir, manifest)
        except Exception as hook_exc:
            manifest["netio_stop_error"] = str(hook_exc)
        return_code = 1
    finally:
        if warmup_netio and not (run_dir / "warmup_netio_samples.csv").exists():
            try:
                manifest["warmup_netio"] = warmup_netio.stop()
            except Exception as exc:
                manifest["warmup_netio_stop_error"] = str(exc)
        if netio and not (run_dir / "netio_samples.csv").exists():
            try:
                manifest.update(netio.stop())
            except Exception as exc:
                manifest["netio_stop_error"] = str(exc)
        for process in monitors:
            try:
                stop_monitor(process)
            except Exception as exc:
                manifest.setdefault("monitor_stop_errors", []).append(str(exc))
        manifest["ended_utc"] = utc_now()
        (run_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        append_ledger(args.output_root, manifest)
    print(json.dumps(manifest, indent=2, sort_keys=True))
    return return_code


if __name__ == "__main__":
    raise SystemExit(main())
