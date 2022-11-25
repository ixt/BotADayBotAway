#!/bin/bash
# More development on the collage bot
set -uo pipefail
IFS=$'\n\t'
SCRIPTDIR="/home/orange/Projects/BotADayBotAway/2018/02/13"
DARKNET="/home/orange/Projects/darknet"
LARGECORPUS="/home/orange/Projects/BotADayBotAway/Tools/google-10000-english/20k.txt"
TEMP=$(mktemp)
_TEMP=$(mktemp)
THRESHOLD="0.01"

. $SCRIPTDIR/.newsapikey
curl -q https://newsapi.org/v2/top-headlines -G \
        -d language=en \
        -d apiKey=$NEWSAPIKEY \
            > sample.json

TARGET=$(~/Projects/BotADayBotAway/Tools/RAKE.sh/RAKE.sh  <(jq -r .articles[].content sample.json  | sed -e "s/\[.*\]//g" -e "/null/d" | sort -u) | cut -f 2 -d, | shuf -n 1)


# Trap things
trap clean_up SIGHUP SIGINT SIGTERM
clean_up(){
    rm -f $SCRIPTDIR/*.csv $SCRIPTDIR/*.png $SCRIPTDIR/*.jpg 
    printf "Leaving COLLAGEBOT\n"
    exit 1
}
getRandomImage() {
    local WORD=$1
    local OUTPUT=${2:-$WORD.png}
    local _SEARCHRESULTS=$(mktemp)

    # Do a search on snappygoat for the phrase
	printf "Getting Random Image: $WORD\n"
    curl "https://snappygoat.com/s/?q=$WORD" -q 2>/dev/null \
        | grep -o 'href="/free[^"]*"' \
        | cut -d'"' -f2 \
	 	| shuf > $_SEARCHRESULTS

    printf "(Results $(wc -l $_SEARCHRESULTS | cut -d' ' -f1))\n" 

    # No results, throw an error
    ! [[ -s "$_SEARCHRESULTS" ]] \
        && (>&2 printf "No results of search\n") \
        && return 1

    [[ "$(wc -l $_SEARCHRESULTS | cut -d' ' -f1)" -eq "1" ]] \
        && (>&2 printf "Search Failure\n") \
        && return 2

    # Pick a random result 
    local IMAGEURL="https://snappygoat.com$(curl "https://snappygoat.com$(shuf -n1 $_SEARCHRESULTS)" 2>/dev/null \
        | grep "Original" \
        | sed 's/.*href="//g' \
        | cut -d'"' -f1 \
        | grep -o "[^ ]*\.[pj][np]g$" \
        | tail -1)"

    # Make sure to check for images on the page 
    [[ -z "$IMAGEURL" ]] \
        && (>&2 printf "No result on image page\n") \
        && return 2

    # Get get the downloaded file's extension
	local EXT=$(rev <<<"$IMAGEURL" \
		| cut -d. -f1 \
		| rev)

    # Download image
	curl "$IMAGEURL" -o "tmp.$EXT" -#

    convert "tmp.$EXT" -resize x800 "$OUTPUT"
    [[ "$?" -ne "0" ]] \
        && (>&2 printf "Image Download Failure\n") \
        && return 2

    rm tmp.$EXT &>/dev/null
    return 0
}
buildCorpus(){
    # Clean the input for conceptnet
    local PHRASE=$(printf $1 | tr '[:upper:]' '[:lower:]')
    local OUTPUT="$2"
    local CORPUS=$(mktemp)
    local JSON=$(mktemp)
    printf "Building corpus for: $PHRASE\n"
    curl -# "http://api.conceptnet.io/c/en/${PHRASE}" -o $JSON
    jq -r '.edges[] | select( .rel.label | test("RelatedTo") ) | .start | select(.language | test("en")) | .label' \
        $JSON >  $CORPUS
    jq -r   '.edges[] | select( .rel.label | test("RelatedTo") ) | .end | select(.language | test("en")) | .label' \
        $JSON >> $CORPUS
    jq -r   '.edges[] | select( .rel.label | test("Synonym") ) | .start | select(.language | test("en")) | .label' \
        $JSON >> $CORPUS
    jq -r     '.edges[] | select( .rel.label | test("Synonym") ) | .end | select(.language | test("en")) | .label' \
        $JSON >> $CORPUS
    # Remove duplicate entries
    sed -i -e "/^$PHRASE$/d" $CORPUS
    awk '!seen[$0]++' $CORPUS > "$OUTPUT"
}
tryFindRelatedImage(){
    local _CORPUS=$(mktemp)
    local PHRASE=$1
    local OUTPUT=${2:-$PHRASE.png}
    printf "Finding related word to: $PHRASE\n"
    buildCorpus $PHRASE $_CORPUS
    while read word; do
        getRandomImage "$word" "$OUTPUT"
        case $? in
            0)
                printf "Done! \"$word\"\n"
                return 0    
            ;;
            1)
                continue
            ;;
            2)
                local count="1"
                while [[ "$count" -le "3" ]]; do
                    printf "Let's try that again $count/3\n"
                    getRandomImage "$word" "$OUTPUT"
                    local ERROR=$?
                    [[ "$ERROR" != "0" ]] \
                        && (( count = count + 1 ))
                    [[ "$ERROR" == "0" ]] \
                        && count=4 \
                        && printf "Done! \"$word\"\n" \
                        && return 0
                done
                [[ "$count" == "3" ]] \
                    && printf "3 Attempts to download that image were made but no progress happened, whats up?\n"
            ;;
            *)    
                printf "Oh no! How is this even supposed to happen?\n"
                return 1
            ;;
            esac
    done < $_CORPUS

    # Ultram clause
    while read NEWWORD; do
        printf "Trying $NEWWORD\n"
        local ucount="1"
        while [[ "$ucount" -le "3" ]]; do
            printf "Let's try (ultram) $ucount/3\n"
            getRandomImage "$NEWWORD" "$OUTPUT"
            local ERROR=$?
            [[ "$ERROR" != "0" ]] \
                && (( ucount = ucount + 1 ))
            [[ "$ERROR" == "0" ]] \
                && count=4 \
                && printf "Done! \"$NEWWORD\"\n" \
                && return 0
        done
        [[ "$ucount" == "3" ]] && printf "3 Attempts to download that image were made but no progress happened, whats up?\n"
    done < <(lynx -dump -nolist -nonumbers "https://duckduckgo.com/?q=$PHRASE" \
            | sed -e "s/ /\n/g" \
            | sed -e "/[^a-zA-Z]/d;/^$/d" \
            | tr '[[:upper:]]' '[[:lower:]]' \
            | sort \
            | sed -e "/^$PHRASE$/d" \
            | uniq -c \
            | sort -r -n \
            | sed -e "s/^[^0-9]*//g" \
            | cut -d" " -f2 \
            | sed -r -e "/^.{,3}$/d" )

    printf "(RELATED IMAGE) Oh no! How is this even supposed to happen?\n"
    return 1
}
getAnImage(){ 
    local PHRASE="${1:-$(shuf -n1 $LARGECORPUS)}"
    local OUTPUT="${2:-$PHRASE.png}"
    getRandomImage "$PHRASE" "$OUTPUT"
    case $? in
        0)    
            printf "Done!\n"
            return 0
        ;;
        1)    
            tryFindRelatedImage "$PHRASE" "$OUTPUT"
        ;;
        2)  
            local count="1"
            while [[ "$count" -le "3" ]]; do
                printf "Let's try that again (regular get) $count/3\n"
                getRandomImage "$PHRASE" "$OUTPUT"
                local ERROR=$?
                [[ "$ERROR" != "0" ]] \
                    && (( count = count + 1 ))
                [[ "$ERROR" == "0" ]] \
                    && count=4 \
                    && printf "Done! \"$PHRASE\"\n" \
                    && return 0
            done
            [[ "$count" == "3" ]] \
                && printf "3 Attempts to download that image were made but no progress happened, whats up?\n"
            [[ "$ERROR" != "0" ]] \
                && tryFindRelatedImage "$PHRASE" "$OUTPUT"
        ;;
        *)    
            printf "(REGULAR GET) Oh no! How is this even supposed to happen?\n"
            return 1
        ;;
    esac
}
pushd $SCRIPTDIR >/dev/null
getPredictions(){
    local INPUT="$1"
    local OUTPUT="$2"
    pushd $DARKNET >/dev/null
    printf "" > "$DARKNET/predictions.json"
    # Give the coproc the file name 
    printf "$INPUT\n" >&"${DARK[1]}"
    
    # Wait for the file to write
    printf "Predicting..."
    while :; do
        grep -q -F "[" "$DARKNET/predictions.json" && break
    done
    printf "Predicted!\n"

    # output the predictions as a csv
    jq -r  ".[] | [.x1, .y1, (.width | floor) , ( .height | floor ), .label] | @csv " predictions.json > "$OUTPUT"

    popd >/dev/null
    printf "" > "$DARKNET/predictions.json"
}
printf "Starting new collage\n"
rm source.png $DARKNET/predictions.jpg &>/dev/null
# Coprocess the darknet interactive terminal
printf "Starting Darknet.\n"
coproc DARK { \
    pushd $DARKNET;
    ./darknet detect \
    cfg/yolov3-tiny.cfg \
    -thresh $THRESHOLD \
    yolov3-tiny.weights;
    popd; \
} 
getSourceImage(){
    getAnImage "$TARGET" "source.png"

    getPredictions "$SCRIPTDIR/source.png" $TEMP
    
    while ! [[ -e $DARKNET/predictions.jpg ]]; do
        [[ -e "source.png" ]] && cp $DARKNET/predictions.jpg predictions.jpg &>/dev/null
    done

    if [[ "2" -gt "$(du $TEMP | grep -o "^[0-9]*")" ]]; then
        rm "source.png" "$DARKNET/predictions.jpg" "predictions.jpg" &>/dev/null
    fi
    sleep 1s
    cp $DARKNET/predictions.jpg sourcePredictions.jpg
}
while ! [[ -e "source.png" ]]; do
    # Having this loop means that if an image fails to have objects
    # in then it will retry the whole process, there isnt any error
    # checking right now, so if there will never be an image then it
    # will just get stuck in a loop
    getSourceImage 
done

PIXELCOUNT=$(identify -format "%h,%w" "$SCRIPTDIR/source.png")
cp source.png output.png

while read WORD; do
    echo $WORD try
    WORDFILE=$(sed -e "s/, /_/g" <<< "$WORD")
    while ! [[ -e "$WORDFILE.png" ]]; do
        while ! [[ -s "$SCRIPTDIR/$WORDFILE.csv" ]]; do
            getAnImage "$WORD" "$SCRIPTDIR/$WORDFILE.png"
            getPredictions "$SCRIPTDIR/$WORDFILE.png" "$SCRIPTDIR/$WORDFILE.csv"
        done
        if ! [[ -s $WORDFILE.csv ]]; then
             rm "$WORDFILE.png"
        fi
        # Get the object most likely to be the requested word
        PREDICTIONLINE=$( grep -no "${WORD}\:[0-9][0-9]" $WORDFILE.csv \
                | sed "s/\:/ /g" \
                | sort -k 3 \
                | tail -1 \
                | cut -d" " -f1 )
        # Put prediction of that object into VALUES array and the crop to new image
        IFS=, read -a VALUES <<<"$(sed -n ${PREDICTIONLINE}p $WORDFILE.csv)"
	    convert "$WORDFILE.png" \
	    	-crop ${VALUES[2]}x${VALUES[3]}+${VALUES[0]}+${VALUES[1]} \
	    	+repage current.png
        if ! [[ -e current.png ]]; then
            convert "$WORDFILE.png" -resize x500 current.png
        fi
        if [[ $(( $RANDOM % 2 )) ]]; then
            python3 grabcut.py
            mv grabcut.png "$WORDFILE.png"
        else
            mv current.png $WORDFILE.png
        fi
        ls *.png
    done
done < <(cut -d'"' -f2 $TEMP | sed "s/:.*//g" | sort | uniq )

# Sort by object size in pixels
cp $TEMP $_TEMP
while read OBJECT; do
    # Pull in the values of the object multiply the width and height append
    # that value to EOL
    IFS=, read -a VALUES <<<"$OBJECT"
    # If and only if, the pixelcount is less than 80% of the source's pixel count
    # To do this we do the multiplication of the width and height then scale it by 25% 
    # then we compare and only append the object if it smaller
    _PIXELCOUNT=$(bc -l <<< "scale=0;(${VALUES[2]} * ${VALUES[3]}) * 1.25" | cut -d. -f1)
    [[ "${_PIXELCOUNT}" -lt "${PIXELCOUNT}" ]] \
        && printf "$OBJECT,$_PIXELCOUNT" >> $_TEMP
done < $TEMP

# Check for objects 
[[ "$(wc -l ${TEMP} | cut -f 1 -d' ')" -eq "0" ]] \
    && exit 0
# Sort the file by last value of line such that highest value is at the top
sort -t, -k6 $_TEMP > $TEMP

cat $TEMP

while read OBJECT; do
    # For every object take in the values and lay out the corrisponding label
    # image onto the "current image"
    IFS=, read -a VALUES <<<"$OBJECT"
	LABEL="$(printf "$(cut -d, -f5- <<< "$OBJECT")" | sed "s/:.*//g;s/\"//g" | sed -e "s/, /_/g")"
    # printf "$LABEL, ${VALUES[0]}, ${VALUES[1]}, ${VALUES[2]}, ${VALUES[3]}\n"
    convert "$LABEL.png" -transparent black -resize ${VALUES[2]}x${VALUES[3]}\! current.png
    convert output.png current.png -geometry +${VALUES[0]}+${VALUES[1]} -composite collage.png
    rm current.png
    mv collage.png output.png
done < $TEMP

# Clean up all those word files
while read WORD; do
    WORDFILE=$(sed -e "s/, /_/g" <<< "$WORD")
    rm $WORDFILE.* 
done < <(cut -d'"' -f2 $TEMP \
            | sed "s/:.*//g" \
            | sort -u )
rm "source.png"

# Posting the updates
ID1=$(twurl -H upload.twitter.com "/1.1/media/upload.json" -f output.png -F media -X POST | jq -r .media_id_string) 
TWEETID=$(twurl "/1.1/statuses/update.json" -d "media_ids=$ID1&status=$TARGET" | jq -r .id_str)
# t reply $TWEETID "Predictions:" -f predictions.jpg
popd >/dev/null
