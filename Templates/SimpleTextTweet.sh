#!/bin/bash
# - Tweet Template
#   YYYYMMDD - template.sh - Description
#   https://ff4500.red/projects/BoaDaBoA/
#   Quote retweet the source tweet
# Add the source tweet to the script 
set -euo pipefail
IFS=$'\n\t'
# Source 
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
../../../Tools/tweet.sh/tweet.sh post "Phrase"
popd
