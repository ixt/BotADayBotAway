#!/bin/bash
# https://twitter.com/LilKevooo/status/930097359324897281
# Posting @200 & @700
# Take the highest retweeted+favorited tweet that trump posted in the last half day
# then screenshot and add a filter to it

# Again using t to fix some missing features of tweet.sh

tweetLink="https://mobile.twitter.com/realDonaldTrump/status/929511061954297857"
tweetRoot="https://mobile.twitter.com/realDonaldTrump/status/"
width="300"
height="1000"
SCRIPTDIR=$(dirname $0)
SCREENSHOT=$(mktemp --suffix=.png)
TEMPPHOTO=$(mktemp --suffix=.png)
LATESTTWEETS=$(mktemp)
TEMP=$(mktemp)
twelveHoursAgo=$(date --date="- 12 hours" +%s)

screenshot(){
    # We repeat this 4 times just to make it takes it 
    fileSize="0"
    echo "[INFO]: Screenshot"
    while [ "${fileSize}" -lt "200000" ]; do
        if [ -e "/usr/bin/chromium" ]; then
        chromium --headless --disable-gpu $tweetLink --hide-scrollbars --virtual-time-budget=20170120 --window-size=${width},${height} --force-device-scale-factor=2 --hide-scroll-bars --screenshot=${SCREENSHOT}
        else
        chromium-browser --headless --disable-gpu $tweetLink --hide-scrollbars --virtual-time-budget=20170120 --window-size=${width},${height} --force-device-scale-factor=2 --hide-scroll-bars --screenshot=${SCREENSHOT}
        fi
        fileSize=$(ls -l ${SCREENSHOT} | cut -d" " -f5)
    done
}

process_photo(){
    # Okay now this is harder to work out than I thought, first we estimate the
    # tweet size taking the lines of a monospaced wrap that is passed to this
    # function. Then we take an upper and lower bound from that esitmate, look
    # up the color of all the pixels in that range to find where to crop
    pixelsHighEstimate=$(( 520 + ( $1 * 50 ) ))
    low=$(bc -l <<< "$pixelsHighEstimate - 75" )
    high=$(bc -l <<< "$pixelsHighEstimate + 75" )
    echo "[INFO]: $pixelsHighEstimate is the high estimate"
    echo "" > ${TEMP}
    echo "[INFO]: Looking for pixels to crop"
    while read y; do 
        values=$(convert ${SCREENSHOT}[1x1+300+${y}] -format "%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]" info:)
        echo $values,$y | grep "230,236,240" >> ${TEMP}
    done < <(seq ${low} ${high})
    pixelsHigh=$(bc -l <<< "$(sed -n 2p ${TEMP} | cut -d, -f4) - 220" )  
    [ "${pixelsHigh}" == "-220" ] && pixelsHigh="${pixelsHighEstimate}"
    echo "[INFO]: Cropping at $pixelsHigh"
    convert ${SCREENSHOT} -crop 600x${pixelsHigh}+0+220 ${TEMPPHOTO}
    # Add a vignette via a pretty over the top way
    convert ${TEMPPHOTO} -alpha set -virtual-pixel transparent -channel A -morphology Distance:-1 Euclidean:0,10\! -background "rgb(200,200,200)" -flatten -crop 600x${pixelsHigh}+0+220 -bordercolor black -border 3x3 output.png 

    # Now we start adding stuff on
    composite \( -geometry 30%,30% -geometry +4+9 halo.png \) output.png ${TEMPPHOTO}
    composite \( -background transparent -gravity SouthEast -geometry +25+75 -rotate "-45" twemoji/2/72x72/1f493.png \) ${TEMPPHOTO} output.png
    composite \( -geometry +5+75 diary.png \) output.png ${TEMPPHOTO}
    side="0"
    downCount="0"
    while read file; do 
        if [ -e "twemoji/2/72x72/$file" ]; then
            rotation=$(seq -45 45 | shuf | head -1)
            if [ "$side" -eq "1" ]; then  
                down=$(bc -l <<< "150 + $downCount")
                along=$(seq 490 515 | shuf | head -1)
                composite \( -background transparent -rotate "$rotation" -geometry +$along+$down twemoji/2/72x72/$file \) output.png ${TEMPPHOTO}
                side="0"
            else
                down=$downCount
                along=$(seq 490 515 | shuf | head -1)
                composite \( -background transparent -rotate "$rotation" -geometry +$along+$down twemoji/2/72x72/$file \) ${TEMPPHOTO} output.png
                side="1"
            fi
            : $(( downCount += (72 + ($RANDOM % 20))))
        fi
    done< <(sed -e "s/^\\\u//g;s/\\\u/-/g;s/.*/\L&/g;s/$/.png/g" $CODEPOINTS | sort | uniq )
    [ "$side" -eq "0" ] && cp ${TEMPPHOTO} output.png
}

pushd $SCRIPTDIR 
# Get the latest tweets and check how old they are, remove from the list the
# ones older than 12 hours old, if they are new check the quantity of retweets & favs
t timeline realdonaldtrump -c | sed -n "/.*\(realDonaldTrump\).*/p" | cut -d"," -f1 | tail -n+2 > ${LATESTTWEETS}
cp ${LATESTTWEETS} ${TEMP}
TEMPTWEETSTORE=$(mktemp)
echo "[INFO]: Grabbing tweets"
while read entry; do 
    ../../../Tools/tweet.sh/tweet.sh get ${entry} > ${TEMPTWEETSTORE}
    postedAt=$(jq .created_at ${TEMPTWEETSTORE} | xargs -I@ date --date="@" +%s)
    if [ "${postedAt}" -lt "${twelveHoursAgo}" ]; then
        sed -i "/^${entry}$/d" ${TEMP}
    else
        retweets=$(jq .retweet_count ${TEMPTWEETSTORE})
        favorites=$(jq .favorite_count ${TEMPTWEETSTORE})
        if [ "${favorites}" -eq "0" ]; then 
            sed -i "/^${entry}$/d" ${TEMP}
        else 
            value=$(bc -l <<< "${favorites} + ${retweets}") 
            sed -i "s/${entry}/${value},${entry}/g" ${TEMP}       
        fi
    fi
done < ${LATESTTWEETS}
sort ${TEMP} > ${LATESTTWEETS}

#Does emoji index exist? 
[ ! -e "emoji.json" ] && wget -qO emoji.json https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json
tweetId=$(tail -n1 ${LATESTTWEETS} | cut -d, -f2 )
tweetLink="${tweetRoot}${tweetId}"
../../../Tools/tweet.sh/tweet.sh get ${tweetLink} > $TEMP
screenshot

CODEPOINTS=$(mktemp)
wordList=$(mktemp)
lineCount=$(jq .full_text $TEMP | sed -e "s/^\"//g;s/\"$//g" | fold -w 34 -s | wc -l )

jq .full_text $TEMP | sed "s/north korea/north_korea/Ig" | sed "s/[^A-Za-z_ ]//g;s/ /\n/g;s/.*/\L&/g" | sed "/^$/d" > ${wordList}
sed -i "/^it$/d;/^it's$/d" $wordList

while read word; do
    TAGS=".[] | select(.tags[] | test(\"^${word}$\")) | .emoji" 
    ALIASES=".[] | select(.aliases[] | test(\"^${word}$\")) | .emoji"
    jq "${TAGS}" emoji.json | sed 's/"//g' | uni2ascii -q -a U >> $CODEPOINTS
    jq "${ALIASES}" emoji.json | sed 's/"//g' | uni2ascii -q -a U >> $CODEPOINTS
    if grep "s$" <<< "$word" ; then
        _word=$(sed -e "s/s$//g" <<< "$word")
        TAGS=".[] | select(.tags[] | test(\"^${_word}\$\")) | .emoji" 
        ALIASES=".[] | select(.aliases[] | test(\"^${_word}\$\")) | .emoji"
        jq "${TAGS}" emoji.json | sed 's/"//g' | uni2ascii -q -a U >> $CODEPOINTS
        jq "${ALIASES}" emoji.json | sed 's/"//g' | uni2ascii -q -a U >> $CODEPOINTS
    fi
done < $wordList
process_photo ${lineCount}

t update " " -f output.png
popd
