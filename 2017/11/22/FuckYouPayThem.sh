#!/bin/bash
# https://twitter.com/hradzka/status/930660751064403970
# Tweets "Fuck you, Pay them." to video scouts wanting to pay with credit 
# Tweets @100, 300, 500, 700 & 900

# Could be improved with checking being impelmented in tweet.sh, if I do
# this/it gets done i'll update the script otherwise we rely on t for better checking

# there may also be an issue with if the same account asks more than once in 12 hours
# if it should or shouldnt tweet twice should really be based on something but right
# now it will just work if twitter is okay with it, really we should add variables 
# to the tweet to stop that if its undesired

# This will only work with the tweet.sh change to make it extended_tweet ready
SCRIPTDIR=$(dirname $0)

LATESTIDS=$(mktemp)
TWEETCONTENT=$(mktemp)
SCREENNAMES=$(mktemp)

# First grab all the tweets from the latest search of "can we use your video for credit"
lynx -dump -listonly 'https://twitter.com/search?f=tweets&q=%20can%20we%20use%20your%20video%20%20for%20credit' | grep "/status/" | cut -d"/" -f6 > $LATESTIDS

fuck(){
    # ../../../Tools/tweet.sh/tweet.sh reply $1 "Fuck you, Pay them."
    t reply $1 "Fսck yoս, Pay them."
    echo "sleeping" 
    sleep $(( (10 + $RANDOM )  % 120 ))s
}

THISROUNDPEOPLE=$(mktemp)
pushd $SCRIPTDIR 
# For every tweet check if it has been seen before 
while read id; do
    if ! egrep -q "^$id" .seenids; then
        # Grab tweet contents and store it 
        ../../../Tools/tweet.sh/tweet.sh get $id > $TWEETCONTENT
        if ! egrep -q "$(jq .user.screen_name $TWEETCONTENT)" $THISROUNDPEOPLE ; then
            if ! egrep -q "pay" <(jq .full_text $TWEETCONTENT); then
                if [ "$(jq .user.followers_count $TWEETCONTENT)" -gt "1000" ]; then
                    fuck $id
                    jq .user.screen_name $TWEETCONTENT >> $THISROUNDPEOPLE
                else
                    # Currently fall back to t for user checking, if not then think they mean well
                    if [ -e "/usr/local/bin/t" ]; then 
                        INREPLY=$(jq .in_reply_to_screen_name $TWEETCONTENT | sed -e 's/"//g;s/\(.*\)/@\1/g')
                        jq .user.description $TWEETCONTENT | grep -o "@.[^ ]*" >> $SCREENNAMES
                        jq .full_text $TWEETCONTENT | grep -o "@.[^ ]*" >> $SCREENNAMES
                        sed -i "/[.\/]/d;/${INREPLY}/d;s/[^a-zA-Z0-9_-@]//g;s/\"//g" $SCREENNAMES
                        COUNT=0
                        while read user; do 
                            FOLLOWERCOUNT=$(t whois -c $user | cut -d, -f7 | tail -1)
                            : $(( COUNT += FOLLOWERCOUNT )) 
                        done < <(sort $SCREENNAMES | uniq | sed "/^$/d")
                        if [ "${COUNT}" -gt "2000" ]; then 
                            fuck $id
                            jq .user.screen_name $TWEETCONTENT >> $THISROUNDPEOPLE
                        fi
                    fi
                fi
            fi
        fi
    fi
    echo $id >> .seenids
    echo " " > $SCREENNAMES
done < $LATESTIDS
popd
