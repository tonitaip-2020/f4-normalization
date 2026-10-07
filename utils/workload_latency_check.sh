#!/usr/bin/env bash
# Run each pgbench workload script separately and print its average latency.
#
# Example:
#   sudo -u postgres -H env PGHOST=/var/run/postgresql PGPORT=5432 \
#     bash workload_latency_check.sh --database imdb_baseline \
#       --workload-root /home/toni/imdb-benchmark/workloads

set -u -o pipefail

database=""
workload_root=""
transactions=5
timeout_seconds=120
pgbench_bin="pgbench"

usage() {
  cat <<'EOF'
Usage:
  workload_latency_check.sh --database DB --workload-root DIR [options]

Options:
  --transactions N       Executions per query script (default: 5)
  --timeout-seconds N    Per-script timeout (default: 120)
  --pgbench PATH         pgbench executable (default: pgbench)
  -h, --help             Show this help

Connection settings come from PGHOST, PGPORT, PGUSER, and PGPASSWORD.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --database|--workload-root|--transactions|--timeout-seconds|--pgbench)
      [[ $# -ge 2 ]] || { echo "$1 requires a value" >&2; exit 2; }
      case "$1" in
        --database) database="$2" ;;
        --workload-root) workload_root="$2" ;;
        --transactions) transactions="$2" ;;
        --timeout-seconds) timeout_seconds="$2" ;;
        --pgbench) pgbench_bin="$2" ;;
      esac
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$database" ]] || { echo "--database is required" >&2; exit 2; }
[[ -n "$workload_root" ]] || { echo "--workload-root is required" >&2; exit 2; }
[[ -d "$workload_root" ]] || { echo "Missing workload root: $workload_root" >&2; exit 2; }
[[ "$transactions" =~ ^[1-9][0-9]*$ ]] || { echo "--transactions must be a positive integer" >&2; exit 2; }
[[ "$timeout_seconds" =~ ^[1-9][0-9]*$ ]] || { echo "--timeout-seconds must be a positive integer" >&2; exit 2; }
command -v "$pgbench_bin" >/dev/null || { echo "pgbench not found: $pgbench_bin" >&2; exit 2; }

if [[ -d "$workload_root/baseline" ]]; then
  baseline_dir="$workload_root/baseline"
elif [[ -d "$workload_root/bl" ]]; then
  baseline_dir="$workload_root/bl"
else
  echo "Missing baseline/ (or legacy bl/) directory under $workload_root" >&2
  exit 2
fi

printf '%-10s %-8s %-18s %-18s %s\n' "SCHEMA" "QUERY" "AVG_LATENCY" "TPS" "STATUS"
printf '%0.s-' {1..76}
printf '\n'

failures=0
for directory in "$baseline_dir" "$workload_root/1nf" "$workload_root/2nf" "$workload_root/4nf"; do
  [[ -d "$directory" ]] || { echo "Missing directory: $directory" >&2; exit 2; }
  schema="$(basename "$directory")"
  [[ "$schema" == "bl" ]] && schema="baseline"

  for query_number in {1..7}; do
    workload="$directory/q$query_number.sql"
    [[ -f "$workload" ]] || { echo "Missing workload: $workload" >&2; exit 2; }

    result="$(
      timeout --foreground "$timeout_seconds"s \
        "$pgbench_bin" -n -M simple -c 1 -j 1 -t "$transactions" \
        -f "$workload" "$database" 2>&1
    )"
    status=$?

    if [[ $status -eq 124 ]]; then
      printf '%-10s %-8s %-18s %-18s %s\n' \
        "$schema" "q$query_number" "-" "-" "TIMED OUT ($timeout_seconds s)"
      failures=$((failures + 1))
      continue
    fi
    if [[ $status -ne 0 ]]; then
      summary="$(printf '%s\n' "$result" | tail -n 1)"
      printf '%-10s %-8s %-18s %-18s %s\n' \
        "$schema" "q$query_number" "-" "-" "FAILED: $summary"
      failures=$((failures + 1))
      continue
    fi

    latency="$(printf '%s\n' "$result" | sed -n 's/^latency average = //p')"
    tps="$(printf '%s\n' "$result" | sed -n 's/^tps = \([^ ]*\).*$/\1/p')"
    printf '%-10s %-8s %-18s %-18s %s\n' \
      "$schema" "q$query_number" "$latency" "$tps" "OK"
  done
done

if [[ $failures -gt 0 ]]; then
  echo "$failures workload check(s) failed or timed out." >&2
  exit 1
fi
