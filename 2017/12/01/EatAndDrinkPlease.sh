#!/bin/bash
# https://twitter.com/worstonlineman/status/236244364236574720
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
../../../Tools/tweet.sh/tweet.sh post "@worstonlineman you should drink water and eat food - $(date +%H)"
popd
