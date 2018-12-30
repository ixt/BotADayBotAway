#!/bin/bash
#   20181230 - BlewMe.sh - Reply to recent tweets with over 5 likes on the
#   selected account and reply with "damn this blew up 😳😳"
#   https://ff4500.red/projects/BoaDaBoA/
# https://twitter.com/neon484/status/1070060918749319168
set -euo pipefail
IFS=$'\n\t'
# Source 
SCRIPTDIR=$(dirname $0)
LATESTTWEETS=$(mktemp)
pushd $SCRIPTDIR 

# Make sure we have a file for tweets we have seen
touch .seenids

printf "Getting tweets\n"

t timeline -c $(t whoami | grep "Screen name" | cut -d@ -f2) \
    | sed -e "/,RT/d" \
        > $LATESTTWEETS

printf "Got tweets\n"

while read tweet; do
    IFS="," read -a tweet_info <<< "$tweet"

    grep -q "${tweet_info[0]}" .seenids \
        && echo "Seen tweet ${tweet_info[0]}" \
        && continue

    printf "Checking tweet ${tweet_info[0]}\n"

    faves=$(t status ${tweet_info[0]} -c \
        | rev \
        | cut -d, -f3 \
        | rev \
        | tail -1)
    if [[ "$faves" -gt 5 ]]; then
        t reply ${tweet_info[0]} "damn this blew up 😳😳"
        echo ${tweet_info[0]} >> .seenids
    fi
done < <(tail -n +2 $LATESTTWEETS)

printf "Done\n"

popd
rm $LATESTTWEETS
