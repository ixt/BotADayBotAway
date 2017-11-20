#!/bin/bash
# 2017-11-20
# https://twitter.com/_jordan_bates/status/902499082567954433
# Posts every day at @146
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
../../../Tools/tweet.sh/tweet.sh post '"He who fights with monsters should look to it that he himself does not become a monster. And if you gaze long into an abyss, the abyss also gazes into you." - Friedrich Nietzsche, Beyond Good and Evil, Aphorism 146 #BoaDaBoA'
popd
