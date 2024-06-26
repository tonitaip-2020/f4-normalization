#/bin/bash

export PGPASSWORD=imdb

# Run powerstat for 60 minutes and 10 seconds, measure in 1s intervals:
sudo powerstat -cDHRf 1 3610 > ../outputs/benchmark_baseline_powerstat_$(date +%Y-%m-%d-%H-%M).txt &
powerstat_pid=$!

# Run sar for 60 minutes and 10 seconds, measure in 1s intervals:
sar -r 1 3610 > ../outputs/benchmark_baseline_mem_$(date +%Y-%m-%d-%H-%M).txt &
sar_pid_mem=$!

# Run sar for 60 minutes and 10 seconds, measure in 1s intervals:
sar -u 1 3610 > ../outputs/benchmark_baseline_cpu_$(date +%Y-%m-%d-%H-%M).txt &
sar_pid_cpu=$!

# Run pgbench
# -c = number of clients
# -f = file to run
# -j = number of threads, must be a multiple of "c"
# -n = required in custom tests
# -T = time to run in seconds, 3600 = 60 min
# -U = postgres user name
# -h = host url
# -p = port, default 5432
pgbench -c 48 -f ../inputs/05a_queries_and_dds_baseline.sql -j 48 -n -T 3600 -U imdb imdb -h localhost -p 5433 > ../outputs/benchmark_baseline_pgbench_$(date +%Y-%m-%d-%H-%M).txt

# Check the exit status of pgbench
if [ $? -eq 0 ]
then
    echo "SQL commands have been executed."
else
    echo "Failure."
fi

kill $powerstat_pid
echo "powerstat has finished."
kill $sar_pid_mem
echo "sar (mem) has finished."
kill $sar_pid_cpu
echo "sar (cpu) has finished."

exit
