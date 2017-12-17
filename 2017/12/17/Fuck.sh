#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# https://twitter.com/Fuzzycow2010/status/938407107724038145
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
FUCK=$(sed -n -e "$(date +%I)p" Fuck.list)
../../../Tools/tweet.sh/tweet.sh post "${FUCK}"
popd
