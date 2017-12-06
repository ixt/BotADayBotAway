#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# https://twitter.com/femdigitale/status/933313881493196808
# Every 2 hours tweet the corresponding tweet, this is on a weekly cycle 

SECONDSSINCEMIDNIGHT=$(( $( TZ=":Etc/GMT-1" date "+(10#%H * 60 + 10#%M) * 60 + 10#%S") )) 
BEATS=$(echo "scale=5;($SECONDSSINCEMIDNIGHT / 86400)*1000" | bc | cut -d. -f1)
DAYOFWEEK=$(date +%w)
SCRIPTDIR=$(dirname $0)
VALUE=$( bc -l <<< "scale=0;($BEATS + ( $DAYOFWEEK * 1000)) / 84 " )

pushd $SCRIPTDIR 
    QUOTE=$(sed -n ${VALUE}p Quotes.list)
    echo «${QUOTE}» - Mister Rogers 
    ../../../Tools/tweet.sh/tweet.sh post "«${QUOTE}» - Mister Rogers" 
# Remove lines that are too long
popd
