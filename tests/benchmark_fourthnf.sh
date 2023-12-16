#/bin/bash

export PGPASSWORD=imdb

# Run powerstat for 30 minutes and 10 seconds, measure in 1s intervals:
sudo powerstat -cDHRf 1 1810 > ../outputs/benchmark_fourthnf_powerstat_$(date +%Y%m%d%H%M).txt &
powerstat_pid=$!

# Run sar for 30 minutes and 10 seconds, measure in 1s intervals:
sar -r 1 1810 > ../outputs/benchmark_fourthnf_sar_mem_$(date +%Y%m%d%H%M).txt &
sar_pid_mem=$!

# Run sar for 30 minutes and 10 seconds, measure in 1s intervals:
sar -u 1 1810 > ../outputs/benchmark_fourthnf_sar_cpu_$(date +%Y%m%d%H%M).txt &
sar_pid_cpu=$!

# Run pgbench
# -c = number of clients
# -f = file to run
# -j = number of threads, must be a multiple of "c"
# -n = required in custom tests
# -T = time to run in seconds, 1800 = 30 min
# -U = postgres user name
# -h = host url
pgbench -c 150 -f ../inputs/05d_queries_and_dds_fourthnf.sql -j 300 -n -T 1800 -U imdb imdb -h localhost > ../outputs/benchmark_fourthnf_pgbench_$(date +%Y%m%d%H%M).txt

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
