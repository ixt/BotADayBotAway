#!/bin/bash
# Takes an array of accounts and the last 100 tweets from those accounts, uses
# markov-bash to generate new text from that and tweet it 
# https://twitter.com/smartkittymomo/status/779727026391515138
SCRIPTDIR=$(dirname $0)
USERS=( "crashtxt" )
SOURCE="$SCRIPTDIR/Sources/$(date +%Y-%m-%d)"
TWEETS=$(mktemp)
pushd $SCRIPTDIR 

if [ ! -e $SOURCE ]; then 
    for USER in ${USERS[@]}; do 
        echo $USER
        t timeline -n 100 -c $USER | grep "^[0-9]" | cut -d, -f1 >> $TWEETS
    done
    
    while read ID; do
        ../../../Tools/tweet.sh/tweet.sh get $ID | jq .full_text \
            | uni2ascii -q -a V | sed -e "s/[^\\\nu0-9A-Fa-f]//g" | sed -e "s/\\\u/ \\\u/g"  >> $SOURCE
    done < $TWEETS
    sed -i -e "s/[^ ]*@[^ ]*//g;s/[*.'\":]//g" $SOURCE
fi
FULLTEXT=$(../../../Tools/markov-bash/markov.sh $SOURCE 100 | sed "s/u/\\\u/g" | ascii2uni -a V -q | sed -e "s/n/\n/g")
echo $FULLTEXT
echo $SOURCE 
../../../Tools/tweet.sh/tweet.sh post ${FULLTEXT}
popd
