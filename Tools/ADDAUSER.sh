#!/bin/bash
set -euo pipefail; IFS=$'\n\t'
# This script grabs the timeline of a given userid and then adds all
# tweets that aren't retweets to the DB

[ ! $1 ] && echo "Provide USERID" && exit 1

SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 

# First we check if the process started already, this is useful for not eating
# too much API while testing. Even though I request no retweets, we filter it
# out anyway
[ ! -e ".batch.tweets.user" ] \
    && twurl "/1.1/statuses/user_timeline.json?user_id=$1&include_rts=false&count=200" > .batch.tweets.user

# Next we filter out all the retweets, to reverse the output just add a "| not"
# in the select function
jq '. - [ .[] | select( .text | test("^RT","x") )]'  .batch.tweets.user > .batch.noretweets.tweets.user

# Now for every item in the JSON array send it's contents to the DB of tweets
for i in $(jq -r 'keys[]' .batch.noretweets.tweets.user); do
    jq ".[$i]" .batch.noretweets.tweets.user \
        | curl -H 'Content-Type: application/json' \
        http://127.0.0.1:5984/tweets \
        -d @-
done

# Then clean
rm .batch.tweets.user .batch.noretweets.tweets.user
popd
