#!/bin/bash
# https://twitter.com/minicacher/status/1879457115
# Although it does not crawl, it does randomly block random users 
SCRIPTDIR=$(dirname $0)

idToHandle(){
    ID=$1
    USER=$(wget -qO- "https://twitter.com/intent/user?user_id=$1" | \
    egrep '<a class="button follow" href="/intent/follow\?screen_name=' | \
    cut -d"=" -f4 | sed 's/">//g' )

    [ "${USER}" == "" ] && return 1
    echo ${USER}
}

pushd $SCRIPTDIR 
STATUS="0"
while [ "$STATUS" == "0" ]; do
    HANDLE=$(IdToHandle $(( $RANDOM * ( $RANDOM % $(date +%Y) ) + $(date +"%d + %m") )))
    [ ! "${HANDLE}" == "" ] && STATUS="1"
done
t block "$HANDLE"
popd
