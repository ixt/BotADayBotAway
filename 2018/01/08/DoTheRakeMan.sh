#!/bin/bash
# In this script I will reference a script from the future!
# (not really im just writing this one to try catch up)

# Take the list of followers grab each of their latest tweets and then randomly pick on to process

echo "This is just going to be psudeocode for now so exit if its exectuted"
exit 0

# TODO: 
# [ ] - Make a manual mode for TheBestest.sh
# [ ] - Decide on how to tweet

# If the tweet database exists don't bother grabbing again
# The DBs should be named for the current hour. 

if tweetDB.currentTime does not exist then
    rm tweetDB* # Remove old tweets

    load_followers
    for follower in followers; do
        get_last_tweet >> tweetDB.currentTime
    done
fi

# sort the database by the latest tweets at the top, grab the latest 100 then
# randomly pick from them

TWEET_ID=$( sort tweetDB.currentTime by postedTime \
	| head -100 \
	| shuf \
	| head -1 )

tweetText \
	| RAKE \
	| xargs -I@ TheBestest.sh "@" E > newStatus

tweet in_reply_to $TWEET_ID "$(cat newStatus)"
