#!/bin/bash
set -euo pipefail
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
i=$(date +%Y%m%d)
if ! ((i%15)); then
    ../../../Tools/tweet.sh/tweet.sh post "FizzBuzz"
elif ! ((i%3)); then
    ../../../Tools/tweet.sh/tweet.sh post "Fizz"
elif ! ((i%5)); then
    ../../../Tools/tweet.sh/tweet.sh post "Buzz"
else
    ../../../Tools/tweet.sh/tweet.sh post "$i"
fi
popd
