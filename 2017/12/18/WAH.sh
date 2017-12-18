#!/bin/bash
# https://twitter.com/smlyc/status/938136273482604544
# Any mentions you get from people with he/him in their bio gets autoreplied
# with the WAH.gif
set -euo pipefail
IFS=$'\n\t'
SCRIPTDIR=$(dirname $0)
ADAYAGO=$(date --date="- 24 hours" +%s)
AMONTHAGO=$(date --date="- 1 month" +%s)
maleFilters=$(mktemp)

pushd $SCRIPTDIR 

cat <<EOF > $maleFilters
he/him
father 
 dad 
EOF

isThisUserARealDude(){
    t whois $1 | grep -i -q -f $maleFilters && return 0
    return 1 
}

wah(){
    # t reply "$1" "" -f "WAH.gif"
    echo "$1" -f "WAH.gif"
}

while read LINE; do 
    IFS=, read -a VALUES <<< "$LINE"
    if [ "${VALUES[1]}" -lt "$AMONTHAGO" ]; then
        sed -i "/^${VALUES[0]}/d" .users
    fi
done < .users

# First Pass, change dates and filter out old dates
while read LINE; do 
    IFS=, read -a VALUES <<< "$LINE"
    DATE=$(date --date="${VALUES[1]}" +%s)
    if [ "$DATE" -gt "$ADAYAGO" ]; then
        if ! grep "^${VALUES[2]}" .users; then
            if isThisUserARealDude ${VALUES[2]}; then
                echo ${VALUES[2]},$DATE >> .users
                wah ${VALUES[0]}
            fi
        else
            echo "seen name in last 24hrs"
        fi
    fi 
done < <(t mentions -c | grep "^[0-9]" | cut -d, -f1-3)
popd
