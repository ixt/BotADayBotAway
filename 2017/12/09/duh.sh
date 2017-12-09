#!/bin/bash
# Takes the last 20 tweets, if they were tweeted less than 10 minutes ago then
# delete and retweet with duh, prepended
# https://twitter.com/django/status/895353163510947840
set -uo pipefail
IFS=$'\n\t'

SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)
TEMPTWEETS=$(mktemp)
CURRENTTIME=$(date --date="- 10 minutes" -u +%s)
URL="https://mobile.twitter.com/search/users?q=NO%20LISTS&s=typd"

pushd $SCRIPTDIR 

while read TWEET; do
    IFS="," read -a info <<< "${TWEET}"
    DATE=$(date --date="$(echo ${info[1]} | sed -e "s/Posted at//Ig")" +%s)
    if [ "${CURRENTTIME}" -lt "${DATE}" ]; then 
        echo ${TWEET} | cut -d, -f4- >> $TEMPTWEETS
        yes | t delete status ${info[0]}
    fi
done < <(t timeline -c $(t whoami -c | cut -d, -f9 | tail -1) | tail -n+1)

while read TWEET; do 
    t update "duh, ${TWEET}"
done < $TEMPTWEETS
popd
