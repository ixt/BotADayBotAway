#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# Archives the names of people, both by appending a name & tweeting it 
# https://twitter.com/ElSangito/status/764301074001899520 
SCRIPTDIR=$(dirname $0)
USERS=( "ElSangito" "_xs" )
DATE=$(date +%s)

pushd $SCRIPTDIR 

for USER in ${USERS[@]}; do
    touch $USER.sums $USER.names
    NAME=$(t whois $USER -c | cut -d, -f10 | sed -n 2p)
    SUM=$(md5sum <<< "$NAME" | cut -d" " -f1)
    if ! grep -q $SUM $USER.sums; then
        t update "New Display name: "$NAME" #$USER"
        echo $SUM >> $USER.sums
        echo $DATE: $NAME >> $USER.names
    fi
done
popd
