#!/bin/bash
LASTTWEETSTAMP=$(t timeline birdbot4 -n 1 -c | cut -d, -f 2 | sed -n 2p | xargs -I@ date --date="@" +%s)
CURRENTSTAMP=$(date +%s)
TIMESINCE=$(bc -l <<<"$CURRENTSTAMP - $LASTTWEETSTAMP")

if [[ "$TIMESINCE" -gt "1800" ]]; then
	exit 1
else
	exit 0
fi
