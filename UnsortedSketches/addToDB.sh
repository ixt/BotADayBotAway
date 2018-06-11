#!/bin/bash
SCRIPTDIR=$(dirname $0)
# Takes twitter id as input
pushd $SCRIPTDIR
../Tools/tweet.sh/tweet.sh fetch "$1" \
    | curl -H 'Content-Type: application/json' \
        http://127.0.0.1:5984/tweets \
        -d @-
popd 

