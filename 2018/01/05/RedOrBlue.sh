#!/bin/bash
# Suggested in class by @goldsmif
set -euo pipefail
IFS=$'\n\t'
SCRIPTDIR=$(dirname $0)
ADAYAGO=$(date --date="- 24 hours" +%s)
AMONTHAGO=$(date --date="- 1 month" +%s)
touch .users

pushd $SCRIPTDIR 

neo(){
    t reply "$1" "Neo from The Matrix in Boots agonising over whether he should buy paracetamol or ibuprofen - Aaron Williams by Jim'll Paint It" -f "RedOrBlue.jpg"
    echo "$1" -f "RedOrBlue.jpg"
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
		if grep -i "red or blue" <<< ${VALUES[3]}; then 
                	echo ${VALUES[2]},$DATE >> .users
                	neo ${VALUES[0]}
		fi
        else
            echo "seen name in last 24hrs"
        fi
    fi 
done < <(t mentions -c | grep "^[0-9]" | cut -d, -f1-4)
popd
