#!/bin/bash
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
../../../Tools/tweet.sh/tweet.sh post 'Take it easy, dude, but take it! - Terence McKenna https://www.youtube.com/watch?v=Hygj2wRODCE'
popd
