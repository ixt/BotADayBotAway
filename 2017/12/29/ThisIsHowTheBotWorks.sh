#!/bin/bash
# How this bot works #BotADayBotAway 
t=$(mktemp --suffix=.sh)
echo \\\\x27 | xargs -i@ echo -e twurl -d @status= > $t
cat $0>>$t
printf "\x27 /1.1/statuses/update.json">>$t
bash $t
