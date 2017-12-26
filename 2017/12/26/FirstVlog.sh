#!/bin/bash
set -euo pipefail
# https://twitter.com/_xs/status/945802646190985216
IFS=$'\n\t'
TEMP=$(mktemp)
JSON=$(mktemp)
NOVID=0
CURRENTTIME=$(date +%s)
YOUTUBELINK="https://www.youtube.com/results?sp=EgIIAQ%253D%253D&search_query=my+first+vlog"
SCRIPTDIR=$(dirname $0)
CURRENTURL=""
pushd $SCRIPTDIR 
lynx -dump -listonly "$YOUTUBELINK" | grep "watch" | cut -d"=" -f2 > ${TEMP}

while [ "$NOVID" -eq "0" ]; do
    ID=$(sed -n 1p $TEMP)
    CURRENTURL="https://youtube.com/watch?v=$ID"
    echo id is $ID
    youtube-dl -s $ID --print-json > $JSON
    UPLOADTIME=$(jq . $JSON | grep -o "mt=[0-9]*&" | sed -e "s/[^0-9]//g" | sort -n | uniq | head -1)
    echo uploaded $UPLOADTIME
    if [ ! "$(( $CURRENTTIME - $UPLOADTIME ))" -gt "3600" ]; then
        NOVID="1"
        echo found a match!
    fi
    sed -n 1d $TEMP
done

TITLE=$(jq .title $JSON)
t update "$TITLE - $CURRENTURL - #FirstVlog"
popd
