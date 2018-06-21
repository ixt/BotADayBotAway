#!/bin/bash
set -euo pipefail; IFS=$'\n\t'
# This script grabs the timeline of the default account and then adds all
# tweets that aren't retweets to the DB

SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 

# First we check if the process started already, this is useful for not eating
# too much API while testing
[ ! -e ".batch.tweets" ] \
    && twurl /1.1/statuses/home_timeline.json?count=200 > .batch.tweets

# Next we filter out all the retweets, to reverse the output just add a "| not"
# in the select function
jq '. - [ .[] | select( .text | test("^RT","x") )]'  .batch.tweets > .batch.noretweets.tweets

# Now for every item in the JSON array send it's contents to the DB of tweets
for i in $(jq -r 'keys[]' .batch.noretweets.tweets); do
    jq ".[$i]" .batch.noretweets.tweets \
        | curl -H 'Content-Type: application/json' \
        http://127.0.0.1:5984/tweets \
        -d @-
done

# Then clean
rm .batch.tweets .batch.noretweets.tweets
popd
