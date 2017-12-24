#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# Wake up in the morning and watch Mr Rogers with me. 
# Tweets out a link to a YouTube video of a Mr Rogers Episode
SCRIPTDIR=$(dirname $0)
LINE=$(shuf ListOfEpisodes | head -1)
pushd $SCRIPTDIR 
IFS=, read -a values <<< "$LINE"
# tweet one 
TWEETID=$(t update "Daily Dose of Mr Rogers: ${values[1]}" 2>&1 | grep -o "status [0-9]*" | grep -o "[0-9]*")
t reply $TWEETID "More info about this episode here: ${values[0]}"
popd
