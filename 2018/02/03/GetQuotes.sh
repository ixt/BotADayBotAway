#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
AUTHORID="44478"
PAGEURL="https://www.goodreads.com/author/quotes/${AUTHORID}"
tempPage=$(mktemp)
PAGE="1"
LARGESTPAGENO="1"

rm -f Quotes.list
while [ "${PAGE}" -le "${LARGESTPAGENO}" ]; do
    wget -qO- "${PAGEURL}?page=${PAGE}" > ${tempPage}
    echo "[INFO]: Getting page ${PAGE} of ${LARGESTPAGENO}"
    LARGESTPAGENO=$(grep next_page ${tempPage} | sed -e"s/?/\n/g" | sed -e "s/^[^>]*=//g" | cut -d'"' -f1 | sed -e "/[^0-9]/d" | sort | tail -1)
    while read QUOTE; do
        echo ${QUOTE} >> Quotes.list
    done < <(grep quoteText -A 1 ${tempPage} | sed -e "/quoteText/d;/--/d;s/\&ldquo\;//g;s/\&rdquo\;//g" | cut -d" " -f7-)
    : $(( PAGE += 1 ))
done

# Remove Breaks
sed -i -e "s/<br \/>/ /g" Quotes.list
# Clean Quotes
sed -i -e "s/[^0-9 »«A-Za-z—.,()\?\!\'-\"]//g" Quotes.list
# Remove lines that are too long
sed -i '/^.\{260,\}$/d' Quotes.list
# Relaces quotation marks with better ones
sed -i "s/\([0-9A-Za-z,.]\)\"/\1»/g;s/\"\([0-9A-Za-z,.]\)/«\1/g" Quotes.list
