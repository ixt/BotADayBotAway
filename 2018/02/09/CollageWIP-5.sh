#!/bin/bash
# More development on the collage bot
set -uo pipefail
IFS=$'\n\t'
SCRIPTDIR="/home/psifork/Projects/botadaybotaway/2018/02/09"
TEMP=$(mktemp)
_TEMP=$(mktemp)
DARKNET="/home/psifork/Pkgs/darknet"
_TEMPCORPUS=$(mktemp)
LARGECORPUS="/home/psifork/Pkgs/google-10000-english/20k.txt"
NUM="0"
FAILS="0"
LOCK_FILE="$SCRIPTDIR/.lock"
TARGET=${1:-$(tail +30 $LARGECORPUS | shuf -n1)}

# Trap things

trap clean_up SIGHUP SIGINT SIGTERM

clean_up(){
    rm -f "$LOCK_FILE" $SCRIPTDIR/*.csv $SCRIPTDIR/*.png $SCRIPTDIR/*.jpg 
    echo "Leaving COLLAGEBOT"
    exit 1
}


getRandomImage() {
    local WORD=$1
    local OUTPUT=${2:-$WORD.png}
    local _SEARCHRESULTS=$(mktemp)
    local _IMAGESONPAGE=$(mktemp)

    # Do a search on snappygoat for the phrase
	printf "Getting Random Image: $WORD\n"
	lynx -dump -listonly "https://snappygoat.com/s/?q=$WORD" \
		| grep -o "https://snappygoat.com/free.*" \
		| shuf > $_SEARCHRESULTS

    printf "Number of results: $(wc -l $_SEARCHRESULTS | cut -d' ' -f1)\n" 

    # No results, throw an error
    ! [[ -s "$_SEARCHRESULTS" ]] \
        && (>&2 printf "No results of search\n") \
        && return 1

    # Pick a random result 
    local IMAGEURL=$(lynx -dump -listonly "$(shuf -n1 $_SEARCHRESULTS)" \
        | grep -o "[^ ]*\.[pj][np]g$" \
        | head -1 )

    # Make sure to check for images on the page 
    [[ -z "$IMAGEURL" ]] \
        && (>&2 printf "No result on image page\n") \
        && return 2

	local EXT=$(rev <<<"$IMAGEURL" \
		| cut -d. -f1 \
		| rev)

	if [ "$IMAGEURL" == "" ]; then
        : $(( FAILS += 1))
        if [ ${FAILS} == 5 ]; then
            FAILS=0
            WORD=""
        fi
	else
		curl "$IMAGEURL" -o "tmp.$EXT" -#
		LOOKINGFORWORD="1"
	fi
    convert tmp.$EXT -resize x800 $OUTPUT.tmp
    mv $OUTPUT.tmp $OUTPUT
    rm tmp.jpg &>/dev/null
    return 0
}

buildCorpus(){
    # Clean the input for conceptnet
    local PHRASE=$(echo $1 | tr '[:upper:]' '[:lower:]')
    local OUTPUT=$2
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
    awk '!seen[$0]++' $CORPUS > $OUTPUT
}

tryFindRelatedImage(){
    local _CORPUS=$(mktemp)
    local PHRASE=$1
    local OUTPUT=${2:-$PHRASE.png}
    printf "Finding related word to: $PHRASE\n"
    buildCorpus $PHRASE $_CORPUS
    while read word; do
        getRandomImage $word $OUTPUT
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
                    getRandomImage $word $OUTPUT
                    local ERROR=$?
                    [[ "$ERROR" != "0" ]] && (( count = count + 1 ))
                    [[ "$ERROR" == "0" ]] && count=4 && printf "Done! \"$word\"\n" && return 0
                done
                [[ "$count" == "3" ]] && printf "3 Attempts to download that image were made but no progress happened, whats up?\n"
            ;;
            *)    
                printf "Oh no! How is this even supposed to happen?\n"
                return 1
            ;;
            esac
    done < $_CORPUS

    # Ultram clause
    local NEWWORD="$( lynx -dump -nolist -nonumbers "https://duckduckgo.com/?q=$PHRASE" \
        | sed -e "s/ /\n/g" \
        | sed -e "/[^a-zA-Z]/d;/^$/d" \
        | tr '[[:upper:]]' '[[:lower:]]' \
        | sort \
        | uniq -c \
        | sort -r -n \
        | head -1 \
        | xargs echo \
        | cut -d" " -f2)"
    echo "Trying $NEWWORD"
    local ucount="1"
    while [[ "$ucount" -le "3" ]]; do
        printf "Let's try (ultram) $ucount/3\n"
        getRandomImage $NEWWORD $OUTPUT
        local ERROR=$?
        [[ "$ERROR" != "0" ]] && (( ucount = ucount + 1 ))
        [[ "$ERROR" == "0" ]] && count=4 && printf "Done! \"$NEWWORD\"\n" && return 0
    done
    [[ "$ucount" == "3" ]] && printf "3 Attempts to download that image were made but no progress happened, whats up?\n"

    printf "(RELATED IMAGE) Oh no! How is this even supposed to happen?\n"
    return 1
    
}

getAnImage(){ 
    local PHRASE=${1:-$(shuf -n1 $LARGECORPUS)}
    local OUTPUT=${2:-$PHRASE.png}
    printf "Getting image of: $PHRASE\n"
    getRandomImage $PHRASE $OUTPUT
    case $? in
        0)    
            printf "Done!\n"
            return 0
        ;;
        1)    
            tryFindRelatedImage $PHRASE $OUTPUT
        ;;
        2)  
            local count="1"
            while [[ "$count" -le "3" ]]; do
                printf "Let's try that again (regular get) $count/3\n"
                getRandomImage $PHRASE $OUTPUT
                local ERROR=$?
                [[ "$ERROR" != "0" ]] && (( count = count + 1 ))
                [[ "$ERROR" == "0" ]] && count=4 && printf "Done! \"$PHRASE\"\n" && return 0
            done
            [[ "$count" == "3" ]] && printf "3 Attempts to download that image were made but no progress happened, whats up?\n"
            [[ "$ERROR" != "0" ]] && tryFindRelatedImage $PHRASE $OUTPUT
        ;;
        *)    
            printf "(REGULAR GET) Oh no! How is this even supposed to happen?\n"
            return 1
        ;;
    esac
}

pushd $SCRIPTDIR >/dev/null

getPredictions(){
    local INPUT=$1
    local OUTPUT=$2
    pushd $DARKNET >/dev/null
    printf "" > "$DARKNET/predictions.json"
    # Give the coproc the file name 
    echo "$INPUT" >&"${DARK[1]}"
    
    # Wait for the file to write
    while :; do
        grep -q -F "[" "$DARKNET/predictions.json" && break
    done

    # output the predictions as a csv
    jq -r  ".[] | [.x1, .y1, (.width | floor) , ( .height | floor ), .label] | @csv " predictions.json > $OUTPUT

    popd >/dev/null
    printf "" > "$DARKNET/predictions.json"
}

printf "Starting new collage\n"

rm source.png $DARKNET/predictions.png &>/dev/null

# Coprocess the darknet interactive terminal
printf "Starting Darknet.\n"
coproc DARK { \
    pushd $DARKNET;
    ./darknet detect \
    cfg/yolov3-tiny.cfg \
    -thresh 0.2 \
    yolov3-tiny.weights &>/dev/null ;
    popd; \
} 

getSourceImage(){
    getAnImage "$TARGET" "source.png"

    getPredictions "$SCRIPTDIR/source.png" $TEMP
    
    while ! [[ -e $DARKNET/predictions.png ]]; do
        [[ -e "source.png" ]] && cp $DARKNET/predictions.png predictions.png &>/dev/null
    done

    if [[ "2" -gt "$(du $TEMP | grep -o "^[0-9]*")" ]]; then
        rm "source.png" "$DARKNET/predictions.png" "predictions.png" &>/dev/null
    fi
}

while ! [[ -e "source.png" ]]; do
    getSourceImage 
done

PIXELCOUNT=$(identify -format "%h,%w" "$SCRIPTDIR/source.png")
cp source.png output.png

while read WORD; do
    while ! [[ -e "$WORD.png" ]]; do
        while ! [[ -s "$SCRIPTDIR/$WORD.csv" ]]; do
            getAnImage $WORD
            getPredictions "$SCRIPTDIR/$WORD.png" "$SCRIPTDIR/$WORD.csv"
        done
        if ! [[ -s $WORD.csv ]]; then
            rm "$WORD.png"
        fi
        # Get the object most likely to be the requested word
        PREDICTIONLINE=$( grep -no "${WORD}\:[0-9][0-9]" $WORD.csv \
                | sed "s/\:/ /g" \
                | sort -k 3 \
                | tail -1 \
                | cut -d" " -f1 )

        # Put prediction of that object into VALUES array and the crop to new image
        IFS=, read -a VALUES <<<"$(sed -n ${PREDICTIONLINE}p $WORD.csv)"
        sed -n ${PREDICTIONLINE}p $WORD.csv
	    convert $WORD.png \
	    	-crop ${VALUES[2]}x${VALUES[3]}+${VALUES[0]}+${VALUES[1]} \
	    	+repage current.png
        python grabcut.py
        mv grabcut.png $WORD.png
    done
done < <(cut -d'"' -f2 $TEMP | sed "s/:.*//g" | sort | uniq )

# Sort by object size in pixels
cp $TEMP $_TEMP
while read OBJECT; do
    # Pull in the values of the object multiply the width and height append
    # that value to EOL
    IFS=, read -a VALUES <<<"$OBJECT"

    # If and only if, the pixelcount is less than 80% of the source's pixel count

    # TO do this we do the multiplication of the width and height then scale it by 25% 
    # then we compare and only append the object if it smaller
    _PIXELCOUNT=$(bc -l <<< "scale=0;(${VALUES[2]} * ${VALUES[3]}) * 1.25" | cut -d. -f1)
    [[ "${_PIXELCOUNT}" -lt "${PIXELCOUNT}" ]] && echo $OBJECT,$_PIXELCOUNT >> $_TEMP
done < $TEMP

# Check for objects 
[[ "$(wc -l ${TEMP} | cut -f 1 -d' ')" -eq "0" ]] && exit 0

# Sort the file by last value of line such that highest value is at the top
sort -t, -k6 $_TEMP > $TEMP


while read OBJECT; do
    # For every object take in the values and lay out the corrisponding label
    # image onto the "current image"
    IFS=, read -a VALUES <<<"$OBJECT"
    LABEL="$(echo "${VALUES[4]}" | sed "s/:.*//g;s/\"//g")"
    echo $LABEL, ${VALUES[0]}, ${VALUES[1]}, ${VALUES[2]}, ${VALUES[3]}
    convert $LABEL.png -transparent black -resize ${VALUES[2]}x${VALUES[3]}\! current.png 
    convert output.png current.png -geometry +${VALUES[0]}+${VALUES[1]} -composite collage.png
    rm current.png
    mv collage.png output.png
done < $TEMP

# Clean up all those word files
while read WORD; do
    rm $WORD.* 
done < <(cut -d'"' -f2 $TEMP | sed "s/:.*//g" | sort | uniq )

rm "source.png"

t update "COLLAGE TEST: $TARGET" -f output.png

popd >/dev/null
