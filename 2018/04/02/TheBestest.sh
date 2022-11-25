#!/bin/bash
# Same as NOISE.sh but with an image instead of random data
set -euo pipefail
IFS=$'\n\t'
CHARS=("▔" "▖" "▗" "▄" "▘" "▌" "▚" "▙" "▝" "▞" "▐" "▟" "▀" "▛" "▜" "▉")
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)
CORPUS="/home/orange/Pkgs/google-10000-english/20k.txt"
WORD="${1:-}"
LOOKINGFORWORD="0"
# Declare an array for storing the array of pixels
declare -A matrix

pushd $SCRIPTDIR >/dev/null
LINE=("" "" "" "" "" "" "" "" "" "" "" "" "")

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
convert current.$IMGEXT -resize 24!x20! -monochrome $TEMP

# Fill up the matrix with all the pixels
[[ "${2:-not e}" != "E" ]] && echo "Loading Matrix with pixels"
for y in $(seq 0 19); do
	for x in $(seq 0 23); do
		values=$(convert ${TEMP}[1x1+${x}+${y}] \
			-format "%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]" \
			info:)
		# Just add all the values together add anything over 200 can be a white pixel
		if [[ "$(echo $values | sed -e "s/,/+/g" | bc -l)" -gt "350" ]]; then
			matrix[$x, $y]=0
		else
			matrix[$x, $y]=1
		fi
	done
done

# Choose the correct characters for a given 4 pixel block
for dy in $(seq 0 9); do
	for dx in $(seq 0 11); do
		x=$(($dx * 2))
		y=$(($dy * 2))
		x1=$(($x + 1))
		y1=$(($y + 1))
		block="${matrix[$x, $y]}${matrix[$x1, $y]}${matrix[$x1, $y1]}${matrix[$x, $y1]}"

		# Given that these are associated to their binary there is likely a better
		# way to do this
		case $block in
			"0000")
				LINE[$dy]=${LINE[$dy]}${CHARS[0]}
				;;
			"0001")
				LINE[$dy]=${LINE[$dy]}${CHARS[1]}
				;;
			"0010")
				LINE[$dy]=${LINE[$dy]}${CHARS[2]}
				;;
			"0011")
				LINE[$dy]=${LINE[$dy]}${CHARS[3]}
				;;
			"0100")
				LINE[$dy]=${LINE[$dy]}${CHARS[4]}
				;;
			"0101")
				LINE[$dy]=${LINE[$dy]}${CHARS[5]}
				;;
			"0110")
				LINE[$dy]=${LINE[$dy]}${CHARS[6]}
				;;
			"0111")
				LINE[$dy]=${LINE[$dy]}${CHARS[7]}
				;;
			"1000")
				LINE[$dy]=${LINE[$dy]}${CHARS[8]}
				;;
			"1001")
				LINE[$dy]=${LINE[$dy]}${CHARS[9]}
				;;
			"1010")
				LINE[$dy]=${LINE[$dy]}${CHARS[10]}
				;;
			"1011")
				LINE[$dy]=${LINE[$dy]}${CHARS[11]}
				;;
			"1100")
				LINE[$dy]=${LINE[$dy]}${CHARS[12]}
				;;
			"1101")
				LINE[$dy]=${LINE[$dy]}${CHARS[13]}
				;;
			"1110")
				LINE[$dy]=${LINE[$dy]}${CHARS[14]}
				;;
			"1111")
				LINE[$dy]=${LINE[$dy]}${CHARS[15]}
				;;
		esac
	done
done

rm current.* >/dev/null
popd >/dev/null


# Echo and then tweet
echo "${LINE[0]}
${LINE[1]}
${LINE[2]}
${LINE[3]}
${LINE[4]}
${LINE[6]}
${LINE[7]}
${LINE[8]}
${LINE[9]}
\"$WORD\" - Orange ($(date +%Y))"
if [[ ! "${2:-not e}" == "E" ]]; then
twurl -d "tweet_mode=extended&status=${LINE[0]}
${LINE[1]}
${LINE[2]}
${LINE[3]}
${LINE[4]}
${LINE[6]}
${LINE[7]}
${LINE[8]}
${LINE[9]}
\"$WORD\" - Orange ($(date +%Y))" /1.1/statuses/update.json
fi
