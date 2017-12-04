#!/bin/bash
# Mix Trump and Drils tweets together 
# https://twitter.com/MadScientist212/status/630879791881662464
SCRIPTDIR=$(dirname $0)
USERS=( "dril" "realDonaldTrump" )
SOURCE="$SCRIPTDIR/Sources/$(date +%Y-%m-%d)"
TWEETS=$(mktemp)
pushd $SCRIPTDIR >/dev/null

# The source document will be produced once a day
if [ ! -e $SOURCE ]; then 

    # For each USER in the list take their last n tweets and add the IDs to a
    # file for later processing 
    for USER in ${USERS[@]}; do 
        >&2 echo $USER 
        t timeline -n 100 -c $USER | grep "^[0-9]" | cut -d, -f1 >> $TWEETS
    done
    
    # Print out the ammount of IDs (hopefully n*#USERS)
    >&2 wc $TWEETS

    >&2 echo "[*] Getting text"
    
    # For every ID check if its a retweet and remove it, the rest add the full
    # text to a source document. Shuffle to IDs to add some "randomness"
    while read ID; do
        ../../../Tools/tweet.sh/tweet.sh get $ID | jq .full_text |\
            sed -e "/^\"RT/d" | sed -e "s/\\\u/ \\\u/g" >> $SOURCE
    done < <( shuf $TWEETS )

    sed -i "s/http[s]*:\/\/[a-zA-Z.\/0-9]*//g;s/^\"//g;s/\"$//g" $SOURCE
else 
    rm -f "$SCRIPTDIR/Sources/$(date --date="- 1 day" +%Y-%m-%d)" 
fi
WORDS=$(seq 10 23 | shuf | head -1)
FULLTEXT=$(../../../Tools/markov-bash/markov.sh $SOURCE $WORDS | sed -e "s/\\\\n/\n/g" | sed -e "s/\\\\/\"/g;s/ \" //g" )
while egrep -i -q -f Connectives <(echo $FULLTEXT); do
#    >&2 echo "bad form: $FULLTEXT"
    FULLTEXT=$(../../../Tools/markov-bash/markov.sh $SOURCE $WORDS | sed -e "s/\\\\n/\n/g" | sed -e "s/\\\\/\"/g;s/ \" //g" )
done

NOOFQUOTES=$(cat <<< "${FULLTEXT}" | egrep -o '"' | wc -l)
eCheck=$(( $NOOFQUOTES & 1 ))
TWEETABLE=""
if [ "$eCheck" -eq "1" ]; then
    TWEETABLE=$(cat <<< "${FULLTEXT}" | sed "s/\([^ ]*\)\"/\"\1\"/g;s/\"\([^ ]*\)/\"\1\"/g" | sed "s/\" /» /g;s/ \"/ «/g" | sed "s/\"//g")
else
    TWEETABLE=$(cat <<< "${FULLTEXT}" | sed "s/\" /» /g;s/ \"/ «/g;s/\"$/»/g;s/^\"/«/g" | sed "s/\"//g")
fi

echo $TWEETABLE
../../../Tools/tweet.sh/tweet.sh post "${FULLTEXT}"
popd >/dev/null
