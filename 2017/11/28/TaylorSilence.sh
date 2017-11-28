#!/bin/bash
# Basically, take the top contriversial posts on reddit world news and find
# keywords using RAKE then put in the template and post a random one 
# fires @019, @089, @198 & @989
# https://twitter.com/awwang1/status/932696394414116865 
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)
pushd $SCRIPTDIR 
while read title; do 
    ../../../Tools/RAKE.sh/RAKE.sh <(echo "${title}") | cut -d, -f2 | tail -1 | xargs -I@ echo "Taylor Swift's silence on @ is deafening" > $TEMP
done < <( wget -qO- 'https://www.reddit.com/r/worldnews/controversial.json' | jq .data.children[].data.title );

../../../Tools/tweet.sh/tweet.sh post "$(shuf $TEMP | head -1)"
popd
