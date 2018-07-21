#!/bin/bash
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)
USER=$1


pushd $SCRIPTDIR >/dev/null

# First search for the date 29 days ago posted by me 
cat << END > $TEMP
{ 
    "selector": {
        "user.id": $USER
    },
    "fields": [ "text", "full_text" ],
    "execution_stats": true
}
END

curl -s -H 'Content-Type: application/json' \
        http://127.0.0.1:5984/tweets/_find \
        -d @- < $TEMP
popd>/dev/null
