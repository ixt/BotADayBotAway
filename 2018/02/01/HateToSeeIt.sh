#!/bin/bash
# https://twitter.com/camflehinger/status/999139149205639168
SOURCEDIR=$(dirname $0)
TEMP=$(mktemp)
pushd $SOURCEDIR
cp .ids $TEMP
# Filter out retweets from timeline, then remove URLS
# Keep all the tweets that contain a question mark 
t ti -e retweets -c benpickman \
    | sed -e 's/[\w \W \s]*http[s]*[a-zA-Z0-9 : \. \/ ; % " \W]*/ /g' \
    | grep "?" \
    | egrep -o "^[0-9]+" \
    >> .ids

# Diff old .ids list with new, then use the diff as a list for replying 
while read id; do
    t reply "$id" "Hate to see it"
    echo "$id" >> $TEMP  
done < <(diff $TEMP <(sort .ids | uniq) | grep "^>" | egrep -o "[0-9]+") 

cp $TEMP .ids

popd 
