#!/bin/bash
# Same as NOISE.sh but with an image instead of random data
set -uo pipefail
IFS=$'\n\t'
SCRIPTDIR="/home/psifork/Projects/botadaybotaway/2018/01/10/"
TEMP=$(mktemp)
CORPUS="/home/psifork/Pkgs/google-10000-english/20k.txt"
DARKNET="/home/psifork/Pkgs/darknet"
WORD="${1:-}"
LOOKINGFORWORD="0"
pushd $SCRIPTDIR >/dev/null

getRandomImage() {
	echo "Getting random image"
	IMGPAGE=$(lynx -dump -listonly "https://snappygoat.com/s/?q=$1" \
		| grep -o "https://snappygoat.com/free.*" \
		| shuf \
		| head -1)
	echo "image page is $IMGPAGE"
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
	else
		echo "image url is $IMGURL"
		wget $IMGURL -O current.$IMGEXT
		LOOKINGFORWORD="1"
	fi
}

while [ "$LOOKINGFORWORD" -lt "1" ]; do
	[[ "${2:-not e}" != "E" ]] && echo "Choosing word"
	[ "$WORD" == "" ] && WORD=$(tail --lines="+2000" $CORPUS | shuf | tail -1)
	[[ "${2:-not e}" != "E" ]] && echo "word is $WORD"
	[[ "${2:-not e}" != "E" ]] && getRandomImage $WORD
	[[ "${2:-not e}" == "E" ]] && getRandomImage $WORD 2>/dev/null >/dev/null
	[[ "${2:-not e}" != "E" ]] && echo "image gotten"
done

WORD=$(echo "$WORD" \
	| tr '[:lower:]' '[:upper:]')

[[ "${2:-not e}" != "E" ]] && echo "Resizing source"
#convert current.$IMGEXT -resize 24!x20! -monochrome $TEMP
COLORS=$(convert current.$IMGEXT -negate -format %c -colorspace LAB -colors 5 histogram:info:- \
	| sort -n -r \
	| cut -d":" -f2 \
	| cut -d")" -f2 \
	| cut -d" " -f2 \
	| head -2 \
	| awk '{printf $0 "-"; getline; print $0}')

echo $COLORS

convert "current.$IMGEXT" -resize 800x "resized.current.png"

pushd $DARKNET
./darknet detect cfg/yolo.cfg yolo.weights $SCRIPTDIR/resized.current.png -thresh 0.1
LOOKINGFORWORD="0"
if ! grep "^0" <(du prediction_details.txt); then
	MAKINGWORK="0"
	NUM="0"
	while read PREDICTION; do
		pushd $SCRIPTDIR
		echo PREDICTION: $PREDICTION
		IFS=, read -a VALUES <<<"$PREDICTION"
		echo ${VALUES[*]}
		convert resized.current.png \
			-crop $((${VALUES[2]} - ${VALUES[1]}))x$((${VALUES[4]} - ${VALUES[3]}))+${VALUES[1]}+${VALUES[3]} \
			+repage uncut.current.png.$NUM
		cp uncut.current.png.$NUM current.png
		python ./grabcut.py
		while [ -e "uncut.current.png.$NUM" ]; do
			: $((NUM += 1))
		done
		convert output.png -trim +repage -transparent black current.png.$NUM
		rm uncut*
		popd
	done < <(rev prediction_details.txt | cut -d, -f-5 | sed -e "s/[^0-9.,]//g" | rev | sort -n)
else
	NUM="0"
	MAKINGWORK="0"
	pushd $SCRIPTDIR
	cp resized.current.png current.png
	python ./grabcut.py
	while [ -e "uncut.current.png.$NUM" ]; do
		: $((NUM += 1))
	done
	convert output.png -compose plus -trim +repage -transparent black current.png.$NUM
	popd
fi
popd

convert -size 1024x1024 current.png.* -transparent black -set page '+%[fx:80*cos((t/n)*2*pi)]+%[fx:80*sin((t/n)*2*pi)]' -layers merge -transparent white collage.png 
convert -size 1024x1024 gradient:$COLORS gradient.png
composite -gravity center collage.png gradient.png aNewImage.png

t update "$WORD" -f aNewImage.png
rm *.png* current.$IMGEXT
popd >/dev/null
