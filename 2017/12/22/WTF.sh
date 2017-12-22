#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# Reply to a random tweet with "WTF is wrong with you?"
# https://twitter.com/GRIMACHU/status/439097776232992768  
SCRIPTDIR=$(dirname $0)
TWEETID=$(t timeline -c -n 200 | grep "^[0-9].*[0-9]$" | cut -d, -f1 | shuf | head -1)
pushd $SCRIPTDIR 
t reply $TWEETID "WTF is wrong with you?"
popd
