#!/bin/bash
# Takes all recent @Comey tweets and translates them too and from various
# languages until it gets back to english then is posted updates once a day @333

# Requires: 
# https://github.com/soimort/translate-shell

# Source:
# https://twitter.com/Erik_R_Krieg/status/850467938767437824
SCRIPTDIR=$(dirname $0)
TEMPIDS=$(mktemp)
t timeline -c Comey | grep "Comey" | cut -d"," -f1 > $TEMPIDS
pushd $SCRIPTDIR 
while read ID; do
    FULLTEXT=$(../../../Tools/tweet.sh/tweet.sh get $ID | jq .full_text)
    if ! egrep -q 'https://t.co' <(echo $FULLTEXT); then
        if ! egrep -q '^"RT ' <(echo $FULLTEXT); then
            if ! egrep -q "$ID" .seenids 2>/dev/null; then
                echo $FULLTEXT | \
                    trans -no-autocorrect :ru --brief | \
                    trans -no-autocorrect :zh-CN --brief | \
                    trans -no-autocorrect :ja --brief | \
                    trans -no-autocorrect :ru --brief | \
                    trans -no-autocorrect :zh-TN --brief | \
                    trans -no-autocorrect :en --brief | \
                    xargs -I@ ../../../Tools/tweet.sh/tweet.sh post "@ - #BoaDaBoa"
                echo $ID > .seenids
            fi
        fi
    fi
done < $TEMPIDS
popd
