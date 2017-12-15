#!/bin/bash
# https://twitter.com/PseudoPlaton/status/936624094182805505
set -euo pipefail
IFS=$'\n\t'
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
t update -f "quithating.jpg"
popd
