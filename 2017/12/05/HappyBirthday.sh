#!/bin/bash
# https://twitter.com/ADDandy/status/575364659315744768
# Wish a happy birthday to people!

SCRIPTDIR=$(dirname $0)
LATESTIDS=$(mktemp)

# First grab all the tweets from the latest search of "its my birthday today"
lynx -dump -listonly 'https://twitter.com/search?f=tweets&q=%22its%20my%20birthday%20today%22&src=typd' | grep "/status/" | cut -d"/" -f6 > $LATESTIDS

birthday(){
    t reply $1 "Happy birthday!"
    # echo https://twitter.com/i/status/$1 "Happy birthday!"
    echo "sleeping" 
    sleep $(( (10 + $RANDOM )  % 120 ))s
}

pushd $SCRIPTDIR 
# For every tweet check if it has been seen before 
while read id; do
    if ! egrep -q "^$id" .seenids; then
        # Grab tweet contents and store it 
        birthday $id
        echo $id >> .seenids
    fi
done < $LATESTIDS
popd
