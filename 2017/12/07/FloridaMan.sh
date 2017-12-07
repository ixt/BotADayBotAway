#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Takes reddit titles from TIFU and posts them as if headlines for "Florida man" stories
# https://twitter.com/Lord_32bit/status/938564683086356480 
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)

# This should eventually generate the list once a week and then re-adjust cron
# based on the amount of matching stories that

# Either this or some form of scheduler / queue system, in that case we would
# hash titles & store for a month to prevent repeats, this random selection
# should be good enough for now

#SECONDSSINCEMIDNIGHT=$(( $( TZ=":Etc/GMT-1" date "+(10#%H * 60 + 10#%M) * 60 + 10#%S") )) 
#BEATS=$(echo "scale=5;($SECONDSSINCEMIDNIGHT / 86400)*1000" | bc | cut -d. -f1)
#DAYOFWEEK=$(date +%w)
#VALUE=$( bc -l <<< "scale=0;($BEATS + ( $DAYOFWEEK * 1000)) / 84 " )

pushd $SCRIPTDIR 

wget -qO- 'https://www.reddit.com/r/tifu/controversial.json?t=week&limit=100' |\
    jq .data.children[].data.title | sed -e "/ my /d;/ I /d;/ she /d" | grep -i '^"TIFU by' |\
    sed -e 's/^"TIFU by//gI;s/"$//g' | xargs -I @ echo "Florida man arrested for @" > $TEMP

../../../Tools/tweet.sh/tweet.sh post "$(shuf $FILE | head -1)"
popd
