#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SECONDSSINCEMIDNIGHT=$(( $( TZ=":Etc/GMT-1" date "+(10#%H * 60 + 10#%M) * 60 + 10#%S") )) 
BEATS=$(echo "scale=5;($SECONDSSINCEMIDNIGHT / 86400)*1000" | bc | cut -d. -f1)
DAYOFWEEK=$(date +%w)
SCRIPTDIR=$(dirname $0)
VALUE=$( bc -l <<< "scale=0;($BEATS + ( $DAYOFWEEK * 1000)) / 125 " )

pushd $SCRIPTDIR 
    QUOTE=$(sed -n ${VALUE}p Quotes.list)
    echo «${QUOTE}» Not Einstien
    twurl -d "tweet_mode=extended&status= «${QUOTE}» Not Einstien" /1.1/statuses/update.json
# Remove lines that are too long
popd
