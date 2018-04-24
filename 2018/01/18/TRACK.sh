#!/bin/bash
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR
    python ./track_followers.py
    while read userid; do 
        t unfollow -i $userid -P 
    done < <(cut -d$'\t' -f1 lost.txt)
    while read userid; do 
        t follow -i $userid -P 
    done < <(cut -d$'\t' -f1 gained.txt)
    rm lost.txt gained.txt
popd
