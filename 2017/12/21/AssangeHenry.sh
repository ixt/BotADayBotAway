#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

# Takes every Julian assange tweet and appends ", Henry"
# https://twitter.com/Smallbrainfield/status/939200035161559040

USER="JulianAssange"
SCRIPTDIR=$(dirname $0)
temp=$(mktemp)
tempTweets=$(mktemp)
seenIds=$(mktemp)

pushd $SCRIPTDIR 

touch .seenids
cp .seenids ${seenIds}

# Check if youve seen a tweet before, add contents to the list if you haven't
echo getting tweets
while read TWEET; do
    IFS="," read -a info <<< "${TWEET}"
    if ! grep ${info[0]} ${seenIds}; then 
        ../../../Tools/tweet.sh/tweet.sh get ${info[0]} | jq .full_text >> $tempTweets
        echo ${info[0]} >> .seenids
    else
        sed -i -e "/${info[0]}/d" ${seenIds}
    fi
done < <(t timeline -c ${USER} -n 40 | grep  "^[0-9]")

# apply changes
echo applying most edits
sed -i "s/^\"//g;s/\"$//g" $tempTweets
sed -i -e"s/“/«/g" -e "s/”/»/g" -e "s/'//g" $tempTweets
sed -i -e"s/http[s]*:\/\/[^ ]*//g" $tempTweets
sed -i "s/[[:space:]]*$//g" $tempTweets
sed -i "s/n$//g" $tempTweets
sed -i "s/[:,.]$//g" $tempTweets

echo Cutting preceeding snails
while grep "^@" $tempTweets; do 
    sed -i "s/^@[^ ]* //g" $tempTweets
    sed -i "s/^@[^ ]*$//g" $tempTweets
done

sed -i -e"/^[[:space:]]*$/d;/^RT/d" $tempTweets
sed -i "s/$/, Henry/g" $tempTweets

while read TWEET; do 
    t update --profile=".trc" --file="./henry.jpg" "${TWEET}"
    echo post "${TWEET}"
done < $tempTweets


while read cleanup; do
   sed -i -e "/${cleanup}/d" .seenids
done < ${seenIds}

popd
