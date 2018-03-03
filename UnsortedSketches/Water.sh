#!/bin/bash
RUNNINGTOTAL=0
TEMP=$(mktemp)

# Search for all the drink glasses of water tweets and extract the number of glasses
/usr/local/bin/t search all "Drink * glasses of water" -c \
    | cut -d"," -f4- \
    | tail -n+2 \
    | grep "\s[0-9]*\sglasses\s" \
    | sed "s/.*\(\s[0-9]*\sglasses\).*/\1/" \
    | cut -d" " -f2 >$TEMP

# Add up all the glasses
while read line; do
	: $((RUNNINGTOTAL += line))
done <$TEMP

LINES=$(cat $TEMP | wc -l)

/usr/local/bin/t update "$(echo 'Remember to drink '$((RUNNINGTOTAL / $LINES))' glasses of water a day! #PSA')"
