#!/bin/bash
# This script takes a given half an hour since epoch and outputs a number, this
# keeps note of where you are in a list, this way I can consistantly get the
# same results from a random list and have a predicted output
SCRIPTDIR=$(dirname $0)
STARTDATE="847633"
affix=" Blood"
DATE=$(date +%s | xargs -I@ echo "( @ - ( @ % 1800 ) ) / 1800" | bc)
line=$(echo "$DATE - $STARTDATE" | bc )
pushd $SCRIPTDIR 
echo "Line number: $line"
word=$(sed -n -e "${line}p" word.list)
# https://www.unix.com/302122718-post2.html?s=34ae4274da01d739c1d2ceda90e4d791
TWEET=$(echo "$word$affix"  | perl -ane ' foreach $wrd ( @F ) { print ucfirst($wrd)." "; } print "\n" ; ')
echo $TWEET
t update -P ~/.trc.allthebloods "$TWEET"
popd
