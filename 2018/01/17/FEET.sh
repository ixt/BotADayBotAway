#!/bin/bash
# https://twitter.com/antifa_catgirl/status/971844688012603392
# Post feet made in Emoji
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)

pushd $SCRIPTDIR

    [ ! -e "emoji.json" ] \
        && wget -qO emoji.json https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json

    [ ! -e "emoji.list" ] \
        && jq -r .[].emoji emoji.json \
        > emoji.list

    ANEMOJI=$(shuf emoji.list | head -1 )

    cat tweet | sed -e "s/@/$ANEMOJI/g" > $TEMP

    bash $TEMP
popd
