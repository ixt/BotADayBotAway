#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

# Takes tweets and inverts the words found in the antonym DB you provide
# https://twitter.com/midraretakes/status/935509320036384770 

USER="realDonaldTrump"
SCRIPTDIR=$(dirname $0)
temp=$(mktemp)
tempTweets=$(mktemp)
seenIds=$(mktemp)

pushd $SCRIPTDIR 

# Download the antonym dictionary if there is none downloaded 
if [ ! -e "antonyms.txt" ]; then
    wget https://github.com/mfaruqui/non-distributional/raw/master/lexicons/antonyms.txt
    sed -i -e "s/Antonym://g" antonyms.txt
fi

touch .seenids
cp .seenids ${seenIds}

# Check if youve seen a tweet before, add contents to the list if you haven't
while read TWEET; do
    IFS="," read -a info <<< "${TWEET}"
    if ! grep ${info[0]} ${seenIds}; then 
        ../../../Tools/tweet.sh/tweet.sh get ${info[0]} | jq .full_text >> $tempTweets
        echo ${info[0]} >> .seenids
    else
        sed -i -e "/${info[0]}/d" ${seenIds}
    fi
done < <(t timeline -c ${USER} | grep  "^[0-9]")

# Search antonym DB for every word, the load the words that match into a database
patternDB=$(mktemp)
words=$(mktemp)
while read WORD; do
    LINE=$(grep "^${WORD}" antonyms.txt)
    IFS=" " read -a info <<< "${LINE}"
    [[ "$LINE" != "" ]] && echo "s/${info[0]}/${info[1]}/Ig" >> $patternDB
done < <( cat $tempTweets | sed -e "s/ /\n/g" | sed -e "s/[^A-Za-z -]//g" |\
                tr '[:upper:]' '[:lower:]')

# apply changes
sed -i -f $patternDB $tempTweets
sed -i "s/^\"//g;s/\"$//g" $tempTweets
sed -i "s/\([0-9A-Za-z,.]\)\"/\1»/g;s/\"\([0-9A-Za-z,.]\)/«\1/g" $tempTweets
sed -i -e"s/“/«/g" -e "s/”/»/g" -e "s/'//g" $tempTweets

while read TWEET; do 
    ../../../Tools/tweet.sh/tweet.sh post ${TWEET}
    echo post "${TWEET}"
done < $tempTweets


while read cleanup; do
   sed -i -e "/${cleanup}/d" .seenids
done < ${seenIds}

popd
