#!/bin/bash
LIMIT="1000"
NEW=$(mktemp)
SCRIPTDIR=$(dirname $0)
OLD="$SCRIPTDIR/tweet.list"

t timeline _xs -n 100 -c \
    | egrep -o "^[0-9]+," \
    | sed -e "s/,//g" \
      > $NEW

ADDITIONS=$(mktemp)
diff $NEW $OLD \
    | grep "^<" \
    | sed -e "s/< //g" \
      > $ADDITIONS

OUT=$(mktemp)
cat $OLD $ADDITIONS > $OUT

tweetTotal=$(cat $OUT | wc -l)

if [[ "$tweetTotal" -gt "$LIMIT" ]]; then
    for id in $(tail -n $(bc -l <<< "$tweetTotal - $LIMIT") $OUT); do
        yes | t delete status $id
        sed -i "/$id/d" $OUT
    done
fi

cp $OUT $OLD

rm $OUT $ADDITIONS $NEW
