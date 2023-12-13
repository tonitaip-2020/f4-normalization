#/bin/bash

export PGPASSWORD=imdb

# Run powerstat for 31 minutes, measure in 0.5s intervals (31 * 60 * 2):
# TODO: this must be higher
sudo powerstat -cDHRf 0.5 3720 > ../outputs/powerstat_populate_fourthnf_$(date +%Y%m%d%H%M).txt &

# Capture the PID of the powerstat process
powerstat_pid=$!

# Run psql in the foreground
psql imdb -U imdb -h localhost -f ../inputs/02d_populate_fourthnf.sql -f ../inputs/03d_create_primary_indices_fourthnf.sql -f ../inputs/04d_create_secondary_indices_fourthnf.sql

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
