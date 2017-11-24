#!/bin/bash
SCRIPTDIR=$(dirname $0)
# Loads down a lot of youtube videos that are in the kings of hearts ost search. 
# then they are filtered to only contain the ones tagged music 

isThis(){
    wget http://www.youtube.com/watch?v=$1 -qO- | grep "Category" -A 6 | cut -d">" -f3 | grep "Music"
    [ $? == "1" ] && echo "not music" && sed -i -e "/${1}/d" .youtubelist && return 0
    echo "music" && return 1
}

pushd $SCRIPTDIR 
    rm .youtubelist
    youtube-dl -i -s ytsearch1000:"kingdom of hearts ost" --get-id | tee -a .youtubelist
    while read url; do
        isThis ${url}
    done < <(cat .youtubelist)
    while read url; do 
        title=$(youtube-dl -s "http://www.youtube.com/watch?v=${url}" --get-title)
        sed -i -e "/^${url}$/d" .youtubelist
        echo $url,$title >> .youtubelist
    done < <(cat .youtubelist)
popd
