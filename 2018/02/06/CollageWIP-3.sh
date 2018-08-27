#!/bin/bash
# More development on the collage bot
set -uo pipefail
IFS=$'\n\t'
SCRIPTDIR="/home/psifork/Projects/botadaybotaway/2018/02/06"
TEMP=$(mktemp)
CORPUS="/home/psifork/Pkgs/google-10000-english/20k.txt"
DARKNET="/home/psifork/Pkgs/darknet"
NUM="0"
FAILS="0"
LOCK_FILE="$SCRIPTDIR/.lock"

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
    yolov3.weights ; \
    popd; \
} &2>&1 >/dev/null

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

while ! [[ -e "source.png" ]]; do
    TARGET=${1:-$(tail +30 $CORPUS | shuf -n1)}
    rm $DARKNET/predictions.png >/dev/null
    getRandomImage "$TARGET" "source.png"


    [[ -e "source.png" ]] && getPredictions "$SCRIPTDIR/source.png" $TEMP

    while ! [[ -e $DARKNET/predictions.png ]]; do
        [[ -e "source.png" ]] && cp $DARKNET/predictions.png predictions.png 2>/dev/null
    done

    if [[ "2" -gt "$(du $TEMP | grep -o "^[0-9]*")" ]]; then
        cat $TEMP
        rm "source.png"
    fi
done

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

while read OBJECT; do
    IFS=, read -a VALUES <<<"$OBJECT"
    LABEL="$(echo "${VALUES[4]}" | sed "s/:.*//g;s/\"//g")"
    echo $LABEL, ${VALUES[0]}, ${VALUES[1]}, ${VALUES[2]}, ${VALUES[3]},
    convert $LABEL.png -transparent black -resize ${VALUES[2]}x${VALUES[3]}\! current.png 
    convert output.png current.png -geometry +${VALUES[0]}+${VALUES[1]} -composite collage.png
    rm current.png
    mv collage.png output.png
done < $TEMP

while read WORD; do
    rm $WORD.* 
done < <(cut -d'"' -f2 $TEMP | sed "s/:.*//g" | sort | uniq )

rm "source.png"

t update "COLLAGE TEST: $TARGET" -f output.png

popd >/dev/null
