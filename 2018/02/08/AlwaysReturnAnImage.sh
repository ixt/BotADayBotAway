#!/bin/bash
# This script will download a public domain image that relates to "$1" to "$2"
set -uo pipefail
IFS=$'\n\t'
SCRIPTDIR="/home/psifork/Projects/botadaybotaway/2018/02/08"
_TEMPCORPUS=$(mktemp)
LARGECORPUS="/home/psifork/Pkgs/google-10000-english/20k.txt"

getRandomImage() {
    local WORD=$1
    local _SEARCHRESULTS=$(mktemp)
    local _IMAGESONPAGE=$(mktemp)

    # Do a search on snappygoat for the phrase
	printf "Getting: $WORD\n"
	lynx -dump -listonly "https://snappygoat.com/s/?q=$WORD" \
		| grep -o "https://snappygoat.com/free.*" \
		| shuf > $_SEARCHRESULTS

    printf "Number of results: $(wc -l $_SEARCHRESULTS | cut -d' ' -f1)\n" 

    # No results, throw an error
    ! [[ -s "$_SEARCHRESULTS" ]] \
        && (>&2 printf "No results of search\n") \
        && return 1

    # Pick a random result 
    local IMAGEURL=$(lynx -dump -listonly "$(shuf -n1 $_SEARCHRESULTS)" \
        | grep -o "[^ ]*\.[pj][np]g$" \
        | head -1 )

    # Make sure to check for images on the page 
    [[ -z "$IMAGEURL" ]] \
        && (>&2 printf "No result on image page\n") \
        && return 2

	local EXT=$(rev <<<"$IMAGEURL" \
		| cut -d. -f1 \
		| rev)

	if [ "$IMAGEURL" == "" ]; then
        : $(( FAILS += 1))
        if [ ${FAILS} == 5 ]; then
            FAILS=0
            WORD=""
        fi
	else
		curl $IMAGEURL -o $WORD.$EXT -#
		LOOKINGFORWORD="1"
	fi
    convert $WORD.$EXT -resize x800 $OUTPUT.tmp
    mv $OUTPUT.tmp $OUTPUT
    rm $WORD.jpg &>/dev/null
}

buildCorpus(){
    # Clean the input for conceptnet
    local PHRASE="$(echo $1 | tr '[:upper:]' '[:lower:]')"
    local OUTPUT="$2"
    local CORPUS=$(mktemp)
    local JSON=$(mktemp)
    printf "Building corpus for: $PHRASE\n"
    curl -# "http://api.conceptnet.io/c/en/${PHRASE}" -o $JSON
    jq -r '.edges[] | select( .rel.label | test("RelatedTo") ) | .start | select(.language | test("en")) | .label' \
        $JSON >  $CORPUS
    jq -r   '.edges[] | select( .rel.label | test("RelatedTo") ) | .end | select(.language | test("en")) | .label' \
        $JSON >> $CORPUS
    jq -r   '.edges[] | select( .rel.label | test("Synonym") ) | .start | select(.language | test("en")) | .label' \
        $JSON >> $CORPUS
    jq -r     '.edges[] | select( .rel.label | test("Synonym") ) | .end | select(.language | test("en")) | .label' \
        $JSON >> $CORPUS
    # Remove duplicate entries
    sed -i -e "/^$PHRASE$/d" $CORPUS
    awk '!seen[$0]++' $CORPUS > $OUTPUT
}

tryFindRelatedImage(){
    local _CORPUS=$(mktemp)
    cp $1 $_CORPUS 
    while read word; do
        getRandomImage $word
        case $? in
            0)
                printf "Done! \"$word\"\n"
                return 0    
            ;;
            1)
                continue
            ;;
            2)
                local count="1"
                while [[ "$count" -le "3" ]]; do
                    printf "Let's try that again $count/3\n"
                    getRandomImage $word
                    [[ "$?" == 2 ]] && $(( count += 1 ))
                done
                printf "3 Attempts to download that image were made but no progress happened, whats up?\n"
            ;;
            *)    
                printf "Oh no! How is this even supposed to happen?\n"
                return 1
            ;;
            esac
    done < $_CORPUS

    while read word; do
        tryFindRelatedImage $_CORPUS
    done < $_CORPUS

    printf "Oh no! How is this even supposed to happen?\n"
    return 1
    
}

getAnImage(){ 
    local PHRASE=${1:-$(shuf -n1 $LARGECORPUS)}
    local OUTPUT=${2:-$PHRASE.png}
    getRandomImage $PHRASE
    case $? in
        0)    
            printf "Done!\n"
            return 0
        ;;
        1)    
            buildCorpus $PHRASE $_TEMPCORPUS
            tryFindRelatedImage $_TEMPCORPUS
        ;;
        2)  
            count="1"
            while [[ "$count" -le "3" ]]; do
                printf "Let's try that again $count/3\n"
                getRandomImage $PHRASE
                [[ "$?" == 2 ]] && $(( count += 1 ))
            done
            printf "3 Attempts to download that image were made but no progress happened, whats up?\n"
            
        ;;
        *)    
            printf "Oh no! How is this even supposed to happen?\n"
            return 1
        ;;
    esac
}

getAnImage
