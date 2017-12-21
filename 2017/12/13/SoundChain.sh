#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# Recursively vist a users soundcloud likes and post one (then repeat for that user)
# https://twitter.com/MysteriousDrD/status/940968557923495936
LASTUSER="gyrotron"
listOfLinks=$(mktemp)
values=$(mktemp)
SCRIPTDIR=$(dirname $0)

pushd $SCRIPTDIR 
# Load in the last user 
if [ -e ".lastuser" ]; then
	LASTUSER=$(sed -n 1p .lastuser)
    echo "Last User set to $LASTUSER"
fi

# Add to list of seen users to prevent loops 
echo "$LASTUSER" >> .seenusers
echo "Added $LASTUSER to seen users"

# Get a list of recent likes 
lynx -dump -listonly https://soundcloud.com/$LASTUSER/likes | cut -d. -f2- | grep "://soundcloud" | sed -e "s/^ //g;/oembed/d;/.xml/d;/\/$/d;/popular\/searches/d" | cut -d/ -f4- | grep "/" | sort > $listOfLinks

echo "List of likes:"
cat $listOfLinks

echo "Users and likes:"
# For every line, get that user's likes and give it a value, this prevents dead ends 
while read LINE; do
	USER=$(cut -d/ -f1 <<< "$LINE" )
	VALUE=$(lynx -dump -listonly https://soundcloud.com/$USER/likes | cut -d. -f2- | grep "://soundcloud" | sed -e "s/^ //g;/oembed/d;/.xml/d;/\/$/d;/popular\/searches/d" | cut -d/ -f4- | grep "/" | sed -e "/^${USER}\//d" | wc -l)
	echo $LINE ${VALUE:0} >> $values
	echo $USER":" ${VALUE:0}
done < $listOfLinks

# Delete seen users from the list and those without any likes
sed -i -e "/ 0$/d;/ 1$/d" $values
while read user; do
	sed -i -e "/${user}/d" $values
done < .seenusers

# Remove those self-cremating assholes
sed -i -e "/${LASTUSER}/d" $values

# Choose a track 
FINALURL="https://soundcloud.com/$(shuf $values | head -1 | cut -d" " -f1)"

# Change the last user value for next run
echo $(cut -d/ -f4 <<< "$FINALURL") > .lastuser

# And post
../../../Tools/tweet.sh/tweet.sh tweet "$LASTUSER liked $FINALURL #SoundChain"
popd
