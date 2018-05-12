#!/bin/bash
# Block any people with US flags in bio
# https://twitter.com/_kttg/status/991899786126082049

echo "Current version has most code there just needs a method of getting ids to check"
exit 0

CURRENTDIR=$(dirname $0)
pushd $CURRENTDIR

checkForSymbol(){ t whois -i "$1" | grep -q 🇺🇸 }

checkAccount(){
    if checkForSymbol "$1"; then
        echo "Block"
        t block -i "$1"
        t unfollow -i "$1"
        echo "$1 - 🔥 🇺🇸 🔥 " >> burntFlags
    else
        echo "No Flag"
    fi
}

for user in ${users[*]}; do
    if ! grep "$user" seen; then
        checkAccount "$user"
        echo "$user" >> seen
    fi
done
popd
