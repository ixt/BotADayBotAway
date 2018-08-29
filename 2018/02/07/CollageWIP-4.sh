#!/bin/bash
# More development on the collage bot
set -uo pipefail
IFS=$'\n\t'
SCRIPTDIR="/home/psifork/Projects/botadaybotaway/2018/02/07"
TEMP=$(mktemp)
_TEMP=$(mktemp)
CORPUS="/home/psifork/Pkgs/google-10000-english/20k.txt"
DARKNET="/home/psifork/Pkgs/darknet"
NUM="0"
FAILS="0"
LOCK_FILE="$SCRIPTDIR/.lock"
TARGET=${1:-$(tail +30 $CORPUS | shuf -n1)}

# Trap things

trap clean_up SIGHUP SIGINT SIGTERM

clean_up(){
    rm -f "$LOCK_FILE" $SCRIPTDIR/*.csv $SCRIPTDIR/*.png $SCRIPTDIR/*.jpg 
    echo "Leaving GTFO"
    exit 1
}

getRandomImage() {
    local WORD=$1
    local OUTPUT=${2:-$WORD.png}
	echo "Getting: $WORD"
	IMGPAGE=$(lynx -dump -listonly "https://snappygoat.com/s/?q=$WORD" \
		| grep -o "https://snappygoat.com/free.*" \
		| shuf \
		| head -1)
	IMGURL=$(lynx -dump -listonly "$IMGPAGE" \
		| grep -o "[^ ]*\.[pj][np]g$" \
		| head -1)
	IMGEXT=$(rev <<<"$IMGURL" \
		| cut -d. -f1 \
		| rev)
	if [ "$IMGURL" == "" ]; then
		echo "no image yet"
	    [ "$WORD" == "" ] && WORD=$(tail --lines="+2000" $CORPUS | shuf | tail -1)
	    [[ "${2:-not e}" != "E" ]] && echo "word is $WORD"
        : $(( FAILS += 1))
        if [ ${FAILS} == 5 ]; then
            FAILS=0
            WORD=""
        fi
	else
		wget $IMGURL -O $WORD.$IMGEXT -q --show-progress
		LOOKINGFORWORD="1"
	fi
    convert $WORD.$IMGEXT -resize x800 $OUTPUT.tmp
    mv $OUTPUT.tmp $OUTPUT
    rm $WORD.jpg >/dev/null
}

pushd $SCRIPTDIR >/dev/null

# Coprocess the darknet interactive terminal
coproc DARK { \
    pushd $DARKNET;
    ./darknet detect \
    cfg/yolov3.cfg \
    -thresh 0.1 \
    yolov3.weights &>/dev/null ; \
    popd; \
} 

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
    if ! grep "^0" <(du predictions.json); then
        jq -r  ".[] | [.x1, .y1, (.width | floor) , ( .height | floor ), .label] | @csv " predictions.json > $OUTPUT
    fi
    popd >/dev/null
    printf "" > "$DARKNET/predictions.json"
}

rm $DARKNET/predictions.png >/dev/null
rm source.png

while ! [[ -e "source.png" ]]; do
    getRandomImage "$TARGET" "source.png"
done

[[ -e "source.png" ]] && getPredictions "$SCRIPTDIR/source.png" $TEMP

while ! [[ -e $DARKNET/predictions.png ]]; do
    [[ -e "source.png" ]] && cp $DARKNET/predictions.png predictions.png 2>/dev/null
done

if [[ "2" -gt "$(du $TEMP | grep -o "^[0-9]*")" ]]; then
    cat $TEMP
    rm "source.png"
fi

PIXELCOUNT=$(identify -format "%h,%w" source.png)
cp source.png output.png

while read WORD; do
    while ! [[ -e "$WORD.png" ]]; do
        getRandomImage $WORD
        getPredictions "$SCRIPTDIR/$WORD.png" "$SCRIPTDIR/$WORD.csv"
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
	    	+repage cut.$WORD.png
        mv cut.$WORD.png $WORD.png
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
