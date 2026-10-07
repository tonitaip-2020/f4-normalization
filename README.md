# Database normalization

## Description

A replication package for creating, denormalizing, normalizing, and testing the performance of the IMDb database. Note: this might not be replicable in a virtual environment.

## Replication instructions

## Replication and benchmark setup

### Experimental boundary

The experiment runs PostgreSQL inside (non-virtualized) Ubuntu. A NETIO device measures wall power for the entire system. Run one benchmark condition at a time.

Each experiment uses one PostgreSQL database containing four PostgreSQL schemas:

```text
public      # baseline (unnormalized) representation
firstnf     # 1NF representation
secondnf    # 2NF representation
fourthnf    # 4NF representation
```

The four representations must contain semantically equivalent IMDb data. Benchmark queries must reference tables with explicit schema qualification, for example `secondnf.title_basics` or `public.title_basics`; do not rely on `search_path`.

### PostgreSQL prerequisites

Install the required packages:

```bash
sudo apt update
sudo apt install -y postgresql-16 postgresql-client-16 postgresql-contrib-16 \
  sysstat pv pipx curl
```

Install `csvkit`, which provides `csvsql` for the IMDb import process:

```bash
pipx ensurepath
pipx install csvkit
export PATH="$HOME/.local/bin:$PATH"
csvsql --version
```

Identify the active PostgreSQL cluster and port:

```bash
sudo pg_lsclusters
```

Use the reported port in every command below. In the example commands, it is stored in `PGPORT`.

```bash
export PGPORT=5433
```

Enable PostgreSQL I/O timing:

```bash
sudo -u postgres -H psql \
  -h /var/run/postgresql \
  -p "$PGPORT" \
  -d postgres \
  -c "ALTER SYSTEM SET track_io_timing = 'on';"

sudo systemctl restart postgresql
```

### Replace your postgresql.conf

Replace your postgresql.conf with the file under `conf`. Back-up the original. Keep in mind that the values therein are for 64 GB RAM.

### Create and populate the IMDb database

Create one database for all schema conditions:

```bash
sudo -u postgres -H createdb \
  -h /var/run/postgresql \
  -p "$PGPORT" \
  --encoding=UTF8 \
  --template=template0 \
  --owner=postgres \
  imdb_baseline
```

Import the original IMDb datasets into the baseline `public` schema. The import workflow uses the IMDb non-commercial datasets and the import script described at <https://gist.github.com/1mehal/13c85e108cbc906f5ec34d28d75b1968>.

Record the dataset download date and SHA-256 checksums of all input files. IMDb datasets change over time; these details are required for exact replication.

If the importer is run as the normal Linux user, configure the connection:

```bash
export PGDATABASE=imdb_baseline
export PGHOST=localhost
export PGPORT=5433
export PGUSER=postgres

bash /path/to/imdb_import_in_postgresql.sh
```

Use the PostgreSQL port reported by `pg_lsclusters`; do not accept an incorrect default offered by the import script.

After the baseline import completes, build the normalized schemas and migrate the equivalent data:

```bash
cd /path/to/f4-normalization

psql -X -v ON_ERROR_STOP=1 \
  -h localhost \
  -p "$PGPORT" \
  -U postgres \
  -d imdb_baseline \
  -f 00_all.sql
```

Verify the resulting schemas:

```bash
psql -h localhost -p "$PGPORT" -U postgres -d imdb_baseline -c '\dn'
```

Run `ANALYZE` after all migrations and index creation:

```bash
psql -X -v ON_ERROR_STOP=1 \
  -h localhost \
  -p "$PGPORT" \
  -U postgres \
  -d imdb_baseline \
  -c 'ANALYZE VERBOSE;'
```

### Workload files

Each schema condition has seven SQL scripts representing the same seven logical query types. The SQL realization differs by physical schema, but each query type must retain the same semantics and parameter distribution across conditions.

Install the workload files in this structure:

```text
/var/lib/postgresql/benchmark/workloads/
├── baseline/
│   ├── q1.sql
│   ├── …
│   └── q7.sql
├── 1nf/
│   ├── q1.sql
│   ├── …
│   └── q7.sql
├── 2nf/
│   ├── q1.sql
│   ├── …
│   └── q7.sql
└── 4nf/
    ├── q1.sql
    ├── …
    └── q7.sql
```

The directory labels `baseline`, `1nf`, `2nf`, and `4nf` are benchmark-condition labels. They correspond respectively to PostgreSQL schemas `public`, `firstnf`, `secondnf`, and `fourthnf`.

Note: if you're using some other IMDb dataset (besides Oct. 7th, 2026), you will need to change the row counts in the .sql files manually before benchmarking.

Make the files readable by PostgreSQL only:

```bash
sudo chown -R postgres:postgres /var/lib/postgresql/benchmark/workloads
sudo chmod -R u=rwX,g=,o= /var/lib/postgresql/benchmark/workloads
```

Each `qN.sql` file is one pgbench transaction script. pgbench randomly selects one of the seven scripts for each transaction, giving every query type probability 1/7. Equal selection probability does not imply equal CPU time, I/O volume, or execution time.

### Measurement runner

Install the benchmark runner:

```bash
sudo install --owner=postgres --group=postgres --mode=700 \
  imdb_benchmark_runner.py \
  /var/lib/postgresql/benchmark/bin/imdb_benchmark_runner.py
```

Store NETIO credentials in a PostgreSQL-readable file:
(if you do not have access to a NETIO device, skip this and the next two steps)

```bash
sudo install -d --owner=postgres --group=postgres --mode=700 \
  /var/lib/postgresql/benchmark/credentials \
  /var/lib/postgresql/benchmark/results

sudo -u postgres -H editor \
  /var/lib/postgresql/benchmark/credentials/netio.env
```

The file must contain:

```bash
NETIO_URL=http://NETIO_IP/netio.json
NETIO_USER=netio
NETIO_PASSWORD=CHANGE_ME
```

Protect it:

```bash
sudo chown postgres:postgres /var/lib/postgresql/benchmark/credentials/netio.env
sudo chmod 600 /var/lib/postgresql/benchmark/credentials/netio.env
```

Run one condition as follows. This example measures the 1NF representation with 32 GB VM RAM:

```bash
sudo -u postgres -H bash -lc '
set -a
. /var/lib/postgresql/benchmark/credentials/netio.env
set +a

python3 /var/lib/postgresql/benchmark/bin/imdb_benchmark_runner.py \
  1nf \
  --scale imdb-1 \
  --ram-gb 32 \
  --database imdb_baseline \
  --workload-root /var/lib/postgresql/benchmark/workloads \
  --output-root /var/lib/postgresql/benchmark/results \
  --device nvme0n1 \
  --duration 3600 \
  --warmup 1200 \
  --clients 48 \
  --jobs 12 \
  --netio-socket-id 4
'
```

For the remaining schema conditions, change only the first positional argument:

```text
baseline
1nf
2nf
4nf
```

All conditions use the same PostgreSQL database name:

```text
--database imdb_baseline
```

The runner saves pgbench output, PostgreSQL I/O snapshots, `iostat`, `vmstat`, raw NETIO samples, a run manifest, and a cumulative result ledger under `/var/lib/postgresql/benchmark/results`.

### Experimental protocol

For every schema × RAM condition:

1. Power off the physical machine.
2. Confirm that the correct NETIO socket reports the host load.
3. Run the fixed warm-up interval.
4. Run the one-hour measured workload.
5. Repeat the condition independently at least five times.
6. Randomize condition order within a block where practical.
7. Preserve all raw result directories and do not overwrite prior runs.

Wall energy from the NETIO socket counter is the primary energy measure. Report energy per transaction (mWh/transaction) as the primary energy-efficiency result; report mean wall power and total energy as secondary measures.
  
