#!/bin/bash
# Use a YOLO to label some public domain photos to post
# You will need to make sure all the paths are correct 
# Im using the modifications in my hosted version of darknet that outputs the
# predicitions to a text file. 
# Can be found here: https://github.com/ixt/darknet
set -uo pipefail
DARKNET="/home/orange/Pkgs/darknet"
CORPUS="/home/orange/Pkgs/google-10000-english/20k.txt"
IFS=$'\n\t'
LOOKINGFORWORD="0"
MAKINGWORK="1"
COUNT="0"
CURRENTTIME=$(date +%Y-%m-%d-%H-%M)
SCRIPTDIR=$(dirname $0)

getRandomImage(){
    echo "Getting random image"
    IMGPAGE=$(lynx -dump -listonly "https://snappygoat.com/s/?q=$1" | grep -o "https://snappygoat.com/free.*" | shuf | head -1)
    echo "image page is $IMGPAGE"
    IMGURL=$(lynx -dump -listonly "$IMGPAGE" | grep -o "[^ ]*\.[pj][np]g$" | head -1)
    IMGEXT=$( rev <<< "$IMGURL" | cut -d. -f1 | rev)
    if [ "$IMGURL" == "" ]; then 
        echo "no image yet"
    else
        echo "image url is $IMGURL"
        wget $IMGURL -O current.$IMGEXT
        LOOKINGFORWORD="1"
    fi
}
pushd $SCRIPTDIR 
ACTUALDIR=$( pwd )
while [ "$MAKINGWORK" == "1" ]; do
    LOOKINGFORWORD="0"
    while [ "$LOOKINGFORWORD" -lt "1" ]; do
        echo "Choosing word"
        WORD=$(tail --lines="+800" $CORPUS | shuf | head -1)
        echo "word is $WORD"
        getRandomImage $WORD
    done
    echo "scaling image"
    [ -e "images/$CURRENTTIME.png" ] && rm images/$CURRENTTIME.png
    convert "current.$IMGEXT" -resize 800x "images/$CURRENTTIME.png"
    
    pushd $DARKNET
    ./darknet detect cfg/yolo.cfg yolo.weights $ACTUALDIR/images/$CURRENTTIME.png
    mv predictions.png $ACTUALDIR/images/$CURRENTTIME.png
    LOOKINGFORWORD="0"
    if ! grep "^0" <(du prediction_details.txt); then
        MAKINGWORK="0"
    fi
    popd 
    [ -e "current.$IMGEXT" ] && rm current.$IMGEXT
#FAILCLOSED
echo $COUNT
[ "$COUNT" -gt "3" ] && exit
: $(( COUNT += 1 ))

done
t update "$CURRENTTIME #YOLOBot12 $IMGPAGE" -f "images/$CURRENTTIME.png" 

popd
