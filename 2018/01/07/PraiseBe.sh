#!/bin/bash
# Checks for a new reply from godtributes and responds with "you can say that again" 
set -euo pipefail
IFS=$'\n\t'
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
TWEET=$(t mentions -c | grep "^[0-9]*," | cut -d, -f1,3 | grep ",godtributes$" | head -1 | cut -d, -f1)
touch .lastseen
if ! grep -q "$TWEET" .lastseen; then
    t reply $TWEET "you can say that again!"
    echo $TWEET > .lastseen
fi
popd

