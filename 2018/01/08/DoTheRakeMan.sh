#!/bin/bash
# In this script I will reference a script from the future!
# (not really im just writing this one to try catch up)

# Take the list of followers grab each of their latest tweets and then randomly pick on to process

# echo "This is just going to be psudeocode for now so exit if its exectuted"
# exit 0

currentTime=$(date +%Y%m%d%H)
TEMP=$(mktemp)
RUNNING=1

# TODO: 
# [ ] - Make a manual mode for TheBestest.sh
# [ ] - Decide on how to tweet

# If the tweet database exists don't bother grabbing again
# The DBs should be named for the current hour. 

while [ "$RUNNING" == 1 ]; do
	if [ ! -e "./tweetDB.$currentTime" ]; then
	    rm tweetDB* # Remove old tweets
	    python ./track_followers.py
	    # This method is slow and hits rate limits really quickly 
	    while read follower; do
	        t timeline -n1 -i -c $follower | cut -d, -f1 | sed -n "2p" >> tweetDB.$currentTime
	        echo $follower
	    done < <(cat followers.txt | shuf | head -100 | sed -e "s/[[:space:]].*$//g" )
	fi
	
	# sort the database by the latest tweets at the top, grab the latest 100 then
	# randomly pick from them
	
	KEY_WORD=""
	while [ "$KEY_WORD" == "" ]; do
	TWEET_ID=$( sort -r -n tweetDB.$currentTime \
		| head -100 \
		| shuf \
		| head -1 )
	
	OWNER=$(../../../Tools/tweet.sh/tweet.sh owner $TWEET_ID)
	
	echo $OWNER $TWEET_ID
	
	KEY_WORD=$(../../../Tools/RAKE.sh/RAKE.sh \
	    <(../../../Tools/tweet.sh/tweet.sh fetch $TWEET_ID \
	                                | jq -r .full_text) \
	                                | head -1 \
	                                | cut -d, -f2- \
                                    | sed -e "s/@[a-zA-Z0-9_-]* //g")
	done
	
	echo $KEY_WORD
	
	../../../2018/04/02/TheBestest.sh "$KEY_WORD" E | sed -e "s/^$//g;s/[[:space:]]$//g" | tee $TEMP
	wc $TEMP | grep "^0"
	[ "$?" == "1" ] && RUNNING=0
done
twurl -d "tweet_mode=extended&in_reply_to_status_id=$TWEET_ID&status=$(cat $TEMP) to $OWNER" /1.1/statuses/update.json


# tweet in_reply_to $TWEET_ID "$(cat newStatus)"
