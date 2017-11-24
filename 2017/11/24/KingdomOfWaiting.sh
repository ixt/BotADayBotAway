#!/bin/bash
# https://twitter.com/Chadunda/status/933569779021041664
# Tweets from a list of videos to @Chadunda who asked for this
# Posts @0 @125 @250 @375 @500 @625 @750 @875 
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
id=$(head -1 .youtubelist | cut -d, -f1)
title=$(head -1 .youtubelist | cut -d, -f2)
../../../Tools/tweet.sh/tweet.sh post "@Chadunda $title https://youtube.com/watch?v=$id"
sed -i 1d .youtubelist
popd
