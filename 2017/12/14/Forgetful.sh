#!/bin/bash
# Search for tweets that contain "i forgot" and reply to them with
# "#NeverForget"
# https://twitter.com/BuucketHe4d/status/510836702211239936 
set -euo pipefail
IFS=$'\n\t'
SCRIPTDIR=$(dirname $0)
LATESTIDS=$(mktemp)

lynx -dump -listonly 'https://twitter.com/search?f=tweets&vertical=default&q=%22I%20forgot%22&src=typd' | grep "/status/" | cut -d"/" -f6 > $LATESTIDS

forget(){
    ../../../Tools/tweet.sh/tweet.sh reply $1 "#NeverForget"
    echo $1 "#NeverForget"
    echo $1 >> .seenids
    echo "sleeping" 
    sleep $(( (10 + $RANDOM )  % 60 ))s
}

THISROUNDPEOPLE=$(mktemp)
pushd $SCRIPTDIR 
# For every tweet check if it has been seen before 
while read id; do
    if ! egrep -q "^$id" .seenids; then
        forget $id
    fi
done < $LATESTIDS
popd
