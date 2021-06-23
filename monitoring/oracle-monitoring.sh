#!/bin/bash


VALIDATOR=$1
echo "Starting oracle-monitoring script..."

# Check every 60 seconds if the missing vote count increases. If more than 2 misses votes in 60 sec, restart the process
while (true); do
    missed_votes=$(terracli query oracle miss $VALIDATOR | sed s/\"//g)

    sleep 60;

    last_missed_votes=$(terracli query oracle miss $VALIDATOR | sed s/\"//g)
    difference=$(expr $last_missed_votes - $missed_votes)

    if [[ $difference -gt 1 ]]
    then
	echo 'Missed votes! -> ' $difference
        restart terrad-price-feeder
	sleep 60 # wait for stabilisation
    fi
done;
