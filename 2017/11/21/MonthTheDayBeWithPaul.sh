#!/bin/bash
# https://twitter.com/Warpgate9/status/931130737868275712
# Retweets @504 everyday, unretweets a months ago after its been running a month 
SCRIPTDIR=$(dirname $0)
DAYS=( "0th" "1st" "2nd" "3rd" "4th" "5th" "6th" "7th" "8th" "9th" "10th" "11th" "12th" "13th" "14th" "15th" "16th" "17th" "18th" "19th" "20th" "21st" "22nd" "23rd" "24th" "25th" "26th" "27th" "28th" "29th" "30th" "31st" )

LASTMONTH=$(TZ=UTC; date --date="-1 month" +%s) 

pushd $SCRIPTDIR 
DAY=$(date +%d)
OLDID=$(egrep "$(echo $LASTMONTH | xargs -Il date --date="@l" +"%B the %d")" ListOfTweets | cut -d, -f2)
ID=$(egrep "$(date +"%B the ${DAYS[$DAY]}")" ListOfTweets | cut -d, -f2)

../../../Tools/tweet.sh/tweet.sh retweet "$ID"
echo $ID
if [ "1511301101" -lt "${LASTMONTH}" ]; then
    ../../../Tools/tweet.sh/tweet.sh unretweet "$OLDID"
fi
popd


