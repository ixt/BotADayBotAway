#!/bin/bash
# This bot is not fully functional yet, lots of broken things and things in the
# wrong place, replacments file is FAR from complete and is not generic enough
# to really achieve much 

tweetRoot="http://mobile.twitter.com/${USER}/status/"
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)

pushd $SCRIPTDIR 

#Does emoji index exist? 
[ ! -e "emoji.json" ] && wget -qO emoji.json https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json
../../../Tools/tweet.sh/tweet.sh get ${1} > $TEMP

CODEPOINTS=$(mktemp)
wordList=$(mktemp)

searchFor(){
    _word=$1
    TAGS=".[] | select(.tags[] | test(\"^${_word}$\")) | .emoji" 
    ALIASES=".[] | select(.aliases[] | test(\"^${_word}$\")) | .emoji"
    DESCRIPTION=".[] | select(.description[] | test(\"^${_word}$\")) | .emoji"
    jq -r "${TAGS}" emoji.json >> $CODEPOINTS
    jq -r "${DESCRIPTION}" emoji.json 2>/dev/null >> $CODEPOINTS
    jq -r "${ALIASES}" emoji.json  >> $CODEPOINTS
}

# We need to fix a few things
jq .full_text $TEMP

jq .full_text $TEMP | sed \
    -e "s/https.*//g" \
    -e "s/\\\n/ /g" \
    -e "s/north korea/north_korea/Ig" \
    -e "s/united kingdom/british/Ig" \
    -e "s/[iI]slam/ star_and_crescent /Ig" \
    -e "s/fine/money/Ig" \
    -e "s/?/question/Ig" \
    -e "s/unclear/grey_question/Ig" \
    -e "s/\bmonday[\'][s]\b/one/Ig" \
    -e "s/\btuesday[\'][s]\b/two/Ig" \
    -e "s/\bwednesday[\'][s]\b/three/Ig" \
    -e "s/\bthursday[\'][s]\b/four/Ig" \
    -e "s/\bfriday[\'][s]\b/five/Ig" \
    -e "s/\bsaturday[\'][s]\b/six/Ig" \
    -e "s/\bsunday[\'][s]\b/seven/Ig" \
    -e "s/1/ one/g" \
    -e "s/2/ two/g" \
    -e "s/3/ three/g" \
    -e "s/4/ four/g" \
    -e "s/5/ five/g" \
    -e "s/6/ six/g" \
    -e "s/7/ seven/g" \
    -e "s/8/ eight/g" \
    -e "s/9/ nine/g" \
    -e "s/0/ zero/g" \
    -e "s/\bdead[A-Za-z]*\b/dead/Ig" \
    | sed "s/[^A-Za-z0-9_ ]//g;s/ /\n/g;s/.*/\L&/g" | sed "/^$/d" > ${wordList}
sed -i "/^it$/d;/^it's$/d" $wordList

cat $wordList

sed -i -f FoxStopList.txt $wordList
sed -i -e "/^[[:space:]]*$/d" $wordList

COUNT=0
while read word; do
    _COUNT=$(wc -l $CODEPOINTS | cut -d" " -f1 )
    searchFor $word
    if grep -q "s$" <<< "$word" ; then
        searchFor $(sed -e "s/s$//g" <<< "$word")
    fi

    searchFor "${word}ing"

    COUNT=$(wc -l $CODEPOINTS | cut -d" " -f1 )
    if [[ "$_COUNT" == "$COUNT" ]]; then 
        searchFor "$(grep $word Replacements.list | cut -d, -f1 | sed -e "s/ /_/g")"

        COUNT=$(wc -l $CODEPOINTS | cut -d" " -f1 )
        if [[ "$_COUNT" == "$COUNT" ]]; then 
            echo "$word" >> $CODEPOINTS
        fi
    fi
done < $wordList

sed -i -e "s/\\uFE0F//g" $CODEPOINTS

cat $CODEPOINTS |  tr '\n' ' '

popd

