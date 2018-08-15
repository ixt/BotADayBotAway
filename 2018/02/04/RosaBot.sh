#!/bin/bash

# The quotes are from goodreads, check the rest of the file for how i got them
# I cleaned them using the GetQuotes script and then manually wnet through to
# remove non-english and repeats
set -euo pipefail
IFS=$'\n\t'
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
SECONDSSINCEMIDNIGHT=$(( $( TZ=":Etc/GMT-1" date "+(10#%H * 60 + 10#%M) * 60 + 10#%S") )) 
BEATS=$(echo "scale=5;($SECONDSSINCEMIDNIGHT / 86400)*1000" | bc | cut -d. -f1)
DAYOFWEEK=$(date +%w)

[[ ! -e Quotes ]] && \
    ./GetQuotes.sh "25616" && \
    cat Quotes.list > Quotes && \
    sed -i -r '/^.{210,}$/d' Quotes

[[ ! -e YouHaventEditiedQuotes ]] && exit 1

AMOUNTOFQUOTES=$(wc -l Quotes | cut -d" " -f1 )
VALUE=$( bc -l <<< "scale=0;($BEATS + ( $DAYOFWEEK * 1000)) / (7000 / $AMOUNTOFQUOTES) " )
    echo $VALUE
    QUOTE=$(sed -n ${VALUE}p Quotes)
    echo «${QUOTE}» - Rosa Luxemburg
    ../../../Tools/tweet.sh/tweet.sh post "«${QUOTE}» - Rosa Luxemburg" 

popd
