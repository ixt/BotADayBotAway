#!/bin/bash
# A bot that grabs pictures of fruit trees and posts it 
FRUITS=( "orange" "lemon" "nectarine" "lime" "peach" "hazelnut" "apple" "pine") 
FRUIT=${FRUITS[$(( $RANDOM % (${#FRUITS} - 1 )))]}

echo "this fruit tree is a $FRUIT tree"
IMGPAGE=$(wget -O- "https://snappygoat.com/s/?q=$FRUIT+tree" | grep -o 'href=\"/free[^"]*"' | sed -e "s/^href=\"//g;s/\"$//g" | shuf | head -1)
echo "image page is $IMGPAGE"
IMGURL=$(wget -O- "https://snappygoat.com$IMGPAGE" | grep -o 'href=\"/o[^"]*"' | sed -e 's/href="//g;s/"//g' | head -1)
echo "image is $IMGURL"
IMGEXT=$( rev <<< "$IMGURL" | cut -d. -f1 | rev)
echo "image url is $IMGURL"
wget --timeout 10 "https://snappygoat.com$IMGURL" -O current.$IMGEXT

t update -f current.$IMGEXT "a $FRUIT tree https://snappygoat.com$IMGPAGE"
