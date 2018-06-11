#!/bin/bash
SCRIPTDIR=$(dirname $0)
PASTDATE=$(date -d "- 29 days" +%Y-%m-%d)
TEMP=$(mktemp)
DELETEFILE=$(mktemp)

# Tool for removing tweets from the database that are 29 dyas old and over. 
# It's a bit of a hack, tweets a date, takes the JSON of that tweet and deletes
# the tweet. Then looks for a date in the database it tweeted that was 29 days ago.
# The tweet it finds it grabs the twitter id of and then searches the database
# for any tweets with a smaller id, as they are sequential anything older than
# that tweet should have a smalelr number. Yea what a hack.


pushd $SCRIPTDIR

# Tweet a date.

ANID=$(../Tools/tweet.sh/tweet.sh tweet "$(date +%Y-%m-%d)" \
    | tee >(curl -s -H 'Content-Type: application/json' \
                http://127.0.0.1:5984/tweets -d @- >/dev/null) \
    | jq -r .id_str )

echo $ANID
sleep 5s
../Tools/tweet.sh/tweet.sh delete "$ANID"

# First search for the date 29 days ago posted by me 
cat << END > $TEMP
{ 
    "selector": {
        "full_text": "$PASTDATE",
        "user.id": 450187541
    },
    "fields": ["_id", "id"],
    "execution_stats": true
}
END

ID=$(curl -s -H 'Content-Type: application/json' \
        http://127.0.0.1:5984/tweets/_find \
        -d @- < $TEMP \
    | jq -r ".docs[].id_str" \
    | sort -n \
    | head -1)

echo "found $ID"

# Then search the database for ids smaller than the one it just found

cat << END > $TEMP
{ 
    "selector": {
        "id_str": {"\$lte": $ID }
    },
    "fields": ["_id", "id_str"],
    "execution_stats": true
}
END

curl -q -H 'Content-Type: application/json' \
        http://127.0.0.1:5984/tweets/_find \
        -d @- < $TEMP \
        | jq -r .docs[]._id > $DELETEFILE

# For every tweet it finds delete the document

while read document; do
    REV=$(curl -s -X GET http://127.0.0.1:5984/tweets/$document | jq -r ._rev )
    curl -s -X DELETE "http://127.0.0.1:5984/tweets/$document?rev=$REV"
    echo "$document deleted $REV"
done < $DELETEFILE

# Clean out for storage

curl -q -H 'Content-Type: application/json' \
    -X POST http://127.0.0.1:5984/tweets/_compact

popd 
