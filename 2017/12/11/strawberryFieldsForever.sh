#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

EMOJI=( "🌿" "🌳" "🌴" "🍃" "🌾" "🌲" "🍓" "🍓" " " " " )
# Makes a strawberry field
# https://twitter.com/_soloform/status/421787068390330368 

SCRIPTDIR=$(dirname $0)
TWEET=""
pushd $SCRIPTDIR 
while read NUM; do
    TWEET="${TWEET}${EMOJI[$NUM]}"
done < <(echo $RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM | sed -e "s/\(.\)/\1\n/g" | grep "^[0-9]") 
../../../Tools/tweet.sh/tweet.sh tweet "$TWEET"
popd
