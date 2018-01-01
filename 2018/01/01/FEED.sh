#!/bin/bash
set -euo pipefail
SCRIPTDIR=$(dirname $0)
temp=$(mktemp)
IFS=$'\n\t'
JSON='https://ff4500.red/feed.json'
pushd $SCRIPTDIR 
touch .seenposts
wget -qO $temp $JSON
jq -r '(map(keys) | add | unique) as $cols | map( . as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' $temp > .currentfeed
rm $temp
touch $temp
while read line; do 
    MD5=$( echo "$line" | md5sum | cut -d" " -f1 )
	if grep -q "$MD5" .seenposts; then
        echo SEEN > /dev/null
    else
        echo $MD5 | tee -a .seenposts
        IFS=@ read -a values <<< "$(echo $line | sed 's/","/@/g' | cut -d@ -f2,4 | sed -e 's/"//g')"
        echo "New: ${values[1]} https://ff4500.red${values[0]}" 
        t update "New: ${values[1]} https://ff4500.red${values[0]}" 
        sleep 1s
    fi
done < .currentfeed
popd
