#/bin/bash

export PGPASSWORD=imdb

# Run powerstat for 60 minutes, measure in 0.5s intervals (60 * 60 * 2):
sudo powerstat -cDHRf 0.5 7200 > ../outputs/populate_secondnf_powerstat_$(date +%Y-%m-%d-%H-%M).txt &

# Capture the PID of the powerstat process
powerstat_pid=$!

# Run psql in the foreground
psql imdb -U imdb -h localhost -f ../inputs/02c_populate_secondnf.sql -f ../inputs/03c_create_primary_indices_secondnf.sql -f ../inputs/04c_create_secondary_indices_secondnf.sql

# Check the exit status of psql
if [ $? -eq 0 ]
then
    echo "SQL commands have been executed."
else
    echo "Failure."
fi

# Terminate the powerstat process using its PID
kill $powerstat_pid
echo "powerstat has finished. All done."
exit

