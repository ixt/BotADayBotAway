#!/bin/bash
# https://twitter.com/UKIPBLACKPOOL_/status/980496412508147714 
# Replies to people asking how the weather is in Saint Petersburg

# TODO: 
# [ ]: form properly into tweet
# [ ]: decide on account name or if to run on own account
# [ ]: branding branding branding

TEMP=$(mktemp)
[[ ! -f ~/.openweathermap.key ]] && echo "Please Authenticate and then continue" && exit 0
# [[ ! -f ~/.trc.russiabot ]] && echo "Please Authenticate and then continue" && exit 0

read API_KEY < ~/.openweathermap.key
curl "http://api.openweathermap.org/data/2.5/weather?id=498817&appid=${API_KEY}" > $TEMP

TEMPERATURE=$( jq -r .main.temp $TEMP )
DESCRIPTION=$( jq -r .weather[].description $TEMP )

echo "$DESCRIPTION and $TEMPERATURE degrees F thanks!"
