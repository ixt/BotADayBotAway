#!/bin/bash
UNIXTIME=$(date +%s)
TIMES=${1:-10}

time {
    ( while read entry; do
        ./CollageWIP-6.sh 2>&1 \
            | tee -a $UNIXTIME.log
    done < <(seq $TIMES) )
}

# Print Successes and count them
echo "Successes: $(grep "delete" $UNIXTIME.log \
    | wc -l \
    | cut -d" " -f1)"

hterm-notify.sh "Test Finished!"
