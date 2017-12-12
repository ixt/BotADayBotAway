#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# Source 
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
../../../Tools/tweet.sh/tweet.sh post "Phrase"
popd
