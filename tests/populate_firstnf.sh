#/bin/bash

export PGPASSWORD=imdb

# Run powerstat for 60 minutes, measure in 0.5s intervals (60 * 60 * 2):
sudo powerstat -cDHRf 0.5 7200 > ../outputs/populate_firstnf_powerstat_$(date +%Y%m%d%H%M).txt &

# Capture the PID of the powerstat process
powerstat_pid=$!

# Run psql in the foreground
psql imdb -U imdb -h localhost -f ../inputs/02b_populate_firstnf.sql -f ../inputs/03b_create_primary_indices_firstnf.sql -f ../inputs/04b_create_secondary_indices_firstnf.sql

# Check the exit status of psql
if [ $? -eq 0 ]
then
    echo "SQL commands have been executed."
else
    echo "Failure."
fi

# Terminate the powerstat process using its PID
# minor-TODO: this hangs the terminal for some reason
kill $powerstat_pid
echo "powerstat has finished. All done."
exit
