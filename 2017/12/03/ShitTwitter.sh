#!/bin/bash
# https://twitter.com/emilio_estimand/status/487120446135873536 
# 40% of 18-24 year olds (who i think might be the majority demographic of
# @dril) use social media in washrooms
# http://time.com/7185/study-young-people-love-to-tweet-from-the-toilet/
SCRIPTDIR=$(dirname $0)
DAYAGO=$(date --date="- 1 day" +%s)
USERS=( "dril" )
TWEETS=$(mktemp)
TWEET=$(mktemp)
pushd $SCRIPTDIR 2>/dev/zero
    for USER in ${USERS[@]}; do 
        t timeline -n 10 -c $USER | grep "^[0-9]" | cut -d, -f1 >> $TWEETS
    done
    while read TWEETID; do
        ../../../Tools/tweet.sh/tweet.sh get ${TWEETID} > $TWEET
        TEXT=$(jq .full_text $TWEET)
        TIMESTAMP=$(jq .created_at $TWEET | xargs -I@ date --date="@" +%s)
        FAVS=$(jq .favorite_count $TWEET)
        SHITTERS=$(bc -l <<< "scale=0;$FAVS * 0.4" | sed -e "s/\..*//g")
        if ! grep -q "^\"RT" <(echo $TEXT); then 
            if [ "${DAYAGO}" -gt "${TIMESTAMP}" ]; then
                if ! grep -q "^${TWEETID}$" .seenids; then
                    t reply ${TWEETID} "Did you know approximately ${SHITTERS} people probably «liked» this while on the toilet?"
                    echo "${TWEETID}" >> .seenids
                fi
            fi
        fi
    done < $TWEETS
popd 2>/dev/zero
