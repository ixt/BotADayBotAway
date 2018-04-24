#!/bin/bash
EXECUTING="$1"
EXECUTED="$2"
ARCHIVEFILE="$3"
DOABLES=$(mktemp)
BATCHSIZE="${4:-1}"

while read ITEM; do
    if ! grep -q -F "$ITEM" "$ARCHIVEFILE"; then
        echo "$ITEM" >> "$DOABLES"
    fi

    [[ "$(wc -l "$DOABLES" | cut -d' ' -f1)" -gt "$(( $BATCHSIZE - 1 ))" ]] && break
done < $2

while read ITEM; do
    $EXECUTING "$PWD/$ITEM"
    [[ $? == 0 ]] && echo "$ITEM" >> "$ARCHIVEFILE"
done < "$DOABLES"

cat $DOABLES
