#!/bin/bash
# https://twitter.com/thought_punk/status/486419466881097728
# Tweet @thought_punk that they want to publish a bunch of short stories someday every month
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
../../../Tools/tweet.sh/tweet.sh post "@thought_punk you want to publish a bunch of short stories someday"
popd
