#!/bin/bash
# Search for tweets that contain "i will die on this hill" or "my hill to die
# on is" and reply to them with "A MARTYR FOR EVERY HILL"
# https://twitter.com/yaelwrites/status/941950908509900801 
set -euo pipefail
IFS=$'\n\t'
SCRIPTDIR=$(dirname $0)
LATESTIDS=$(mktemp)

lynx -dump -listonly 'https://twitter.com/search?q=I%20will%20die%20on%20this%20hill' | grep "/status/" | cut -d"/" -f6 > $LATESTIDS
lynx -dump -listonly 'https://twitter.com/search?q=my%20hill%20to%20die%20on%20is' | grep "/status/" | cut -d"/" -f6 >> $LATESTIDS

martyr(){
    ../../../Tools/tweet.sh/tweet.sh reply $1 "A MARTYR FOR EVERY HILL"
    echo $1 "A MARTYR FOR EVERY HILL"
    echo $1 >> .seenids
    echo "sleeping" 
    sleep $(( (10 + $RANDOM )  % 60 ))s
}

THISROUNDPEOPLE=$(mktemp)
pushd $SCRIPTDIR 
# For every tweet check if it has been seen before 
while read id; do
    if ! egrep -q "^$id" .seenids; then
        martyr $id
    fi
done < $LATESTIDS
popd
