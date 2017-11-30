#!/bin/bash
# Effectively do a bunch of stuff with headlines in newbotbot to make AWS to
# RWS and amazon to relentless.com Most interesting is using hashing to
# hopefully prevent the repeats but might end up backfiring or being too heavy
# handed
# Will check every hour.
# https://twitter.com/rsiegel/status/875749724933980164
SCRIPTDIR=$(dirname $0)
list=$(mktemp)
clean=$(mktemp)
abstract=$(mktemp)
pushd $SCRIPTDIR >/dev/null
wget -qO- 'https://www.reddit.com/r/newsbotbot/search.json?q=amazon+&restrict_sr=on&sort=new&t=all' |\
    jq .data.children[].data.title |\
    sed -e "/RT/d;s/^\"//g;s/\"$//g" \
    > $list
count=0
while read title; do
    : $(( count += 1 ))
    echo "$title" | sed -e "s/@[A-Za-z0-9]*//g;s/http[s]*:\/\/[a-zA-Z.\/0-9]*//g;s/#[^ ]*//g;/RT/d;s/,//g" -e "s/$/,$count/g" >> $clean
done < $list
cat $clean | sed -e "s/ [^A-Z,][^ 0-9,]*//g" | sort | rev | uniq -f1 | rev > $abstract
while read abstract; do 
    cleanAbstract=$(cut -d, -f1  <<< "$abstract")
    lineNo=$(cut -d, -f2  <<< "$abstract")
    sum=$(echo $cleanAbstract | sha256sum | cut -d" " -f1)
    if ! egrep -q "^$sum$" checked; then
        echo $sum >> checked
        sed -n ${lineNo}p $list | sed -e "s/Amazon/Relentless.com/Ig;s/AWS/RWS/Ig" | cut -d: -f2- | sed -e "s/^ //g"
    fi
done < $abstract
#../../../Tools/tweet.sh/tweet.sh post "Phrase"
popd >/dev/null
