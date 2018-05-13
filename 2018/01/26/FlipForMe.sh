#!/bin/bash
# If a mention contains "#FlipForMe"
IDS=()
CURRENTDIR=$(dirname $0)

flipACoin(){
    if [[ $(bc <<< "$RANDOM % 2") == "0" ]]; then
        t reply "$1" "HEADS!" -f heads.png
    else
        t reply "$1" "TAILS!" -f tails.png
    fi
}

pushd $CURRENTDIR

# Get recent mentions and iterate through them adding them to IDS if havent seen
while read id; do
    if ! grep -q "$id" .seenids; then
    IDS+=("$id")
    echo "$id" >> .seenids
    fi
done < <(t mentions -c | grep "^[0-9]*," | cut -d, -f1 )


for ID in ${IDS[*]}; do
    ../../../Tools/tweet.sh/tweet.sh body "$ID"| grep -q -i "#FlipForMe"
    if [[ "$?" == "0" ]]; then
        echo "a flip"
        flipACoin "$ID"
    else
        echo "no flip"
    fi
done
popd
