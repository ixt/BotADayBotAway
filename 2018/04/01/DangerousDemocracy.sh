#!/bin/bash
# Take new news from r/worldnews and post it the title has a phrase in it
# include the phrase "This is extremely dangerous to our democracy"
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)
pushd $SCRIPTDIR 
wget -qO- 'https://www.reddit.com/r/worldnews/new.json' \
	| jq '[ .data.children[].data ]' \
	| jq -c 'map( select( .title | contains("death", "facebook", "democracy", "trust", "data", "google")))' \
	| jq -r .[].url \
	| sed -e "s/^/This is extremely dangerous to our democracy /g" \
	> $TEMP

../../../Tools/tweet.sh/tweet.sh post "$(shuf $TEMP | head -1)"
popd
