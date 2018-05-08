#!/bin/bash
NUMBER=$RANDOM
if [[ $(( $NUMBER % 2 )) == 0 ]]; then
    BORDER="white"
else 
    BORDER="black"
fi

convert -background blue -pointsize 1500 -fill orangered label:"$NUMBER" -trim +repage -resize 700x700! -bordercolor $BORDER -border 100x100 "number.png"
echo "$NUMBER $BORDER"
t update -P ~/.trc.randomnoaday -f number.png "$NUMBER"
rm number.png
