#!/bin/bash
# https://twitter.com/diogenessynope/status/1000770637240160256
# A bot that takes @dalailama's tweets and posts them with an appended ",
# motherfucker"
SOURCEDIR=$(dirname $0)
TEMP=$(mktemp)
STATUSES=$(mktemp)
pushd $SOURCEDIR
touch .ids
cp .ids $TEMP
t ti -c dalailama -e retweets | egrep -o "^[0-9]+" >> .ids
while read id; do
    ../../../Tools/tweet.sh/tweet.sh body $id >> $STATUSES
    echo $id >> $TEMP
done < <(diff $TEMP <(sort .ids | uniq) | grep "^>" | egrep -o "[0-9]+")

sed -i -e 's/[\w \W \s]*http[s]*[a-zA-Z0-9 : \. \/ ; % " \W]*/ /g' $STATUSES
sed -i -e "s/\([^[:alpha:]]\)*$/, motherfucker\1/g" $STATUSES

while read status; do
    #../../../Tools/tweet.sh/tweet.sh post "$status"
    echo "../../../Tools/tweet.sh/tweet.sh post $status"
done < $STATUSES

cp $TEMP .ids
popd 
rm $TEMP $STATUSES >/dev/null
