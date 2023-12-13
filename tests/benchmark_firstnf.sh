#/bin/bash

export PGPASSWORD=imdb

# Run powerstat for 60 minutes, measure in 1s intervals (60 * 60):
sudo powerstat -cDHRf 1 7200 > ../outputs/powerstat_benchmark_baseline_$(date +%Y%m%d%H%M).txt &

# Capture the PID of the powerstat process
powerstat_pid=$!

# Run sar for 60 minutes, measure in 1s intervals:
sar -r 1 7200 > ../outputs/sar_mem_benchmark_baseline_$(date +%Y%m%d%H%M).txt &

# Capture the PID of the sar process
sar_pid_mem=$!

# Run sar for 60 minutes, measure in 1s intervals:
sar -u 1 7200 > ../outputs/sar_cpu_benchmark_baseline_$(date +%Y%m%d%H%M).txt &

# Capture the PID of the sar process
sar_pid_cpu=$!

# Run pgbench
# -c = number of clients
# -f = file to run
# -j = number of threads, must be a multiple of "c"
# -n = required in custom tests
# -T = time to run in seconds
# -U = postgres user name
# -h = host url
pgbench -c 10 -f ../inputs/05a_queries_and_dds_baseline.sql -j 10 -n -T 10 -U imdb imdb -h localhost > ../outputs/pgbench_benchmark_baseline_$(date +%Y%m%d%H%M).txt

# Check the exit status of psql
if [ $? -eq 0 ]
then
    echo "SQL commands have been executed."
else
    echo "Failure."
fi

kill $powerstat_pid
kill $sar_pid_mem
kill $sar_pid_cpu
echo "powerstat has finished. All done."
exit
