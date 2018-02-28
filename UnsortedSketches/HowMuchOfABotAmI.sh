#!/bin/bash
# Use the Botometer API to tweet your bot score! via python & there tweep package
# Yes I do realise it can just be done purely in python and totally doesnt need me to use T
# But for the sake of me being able to easily move this around machines I like to have it in
# a similar format to other scripts

PYTEMP=$(mktemp)
TEMP=$(mktemp)

# Get Current Profiles keys and info
consumer_key=$(head -5 ~/.trc | tail -1 | sed -e "s/-//g" -e "s/[[:space:]]//g")
tail -n+$(sed -n "/$consumer_key/=" ~/.trc | head -2 | tail -1) ~/.trc | head -6 > $TEMP

consumer_secret=$(grep "consumer_secret" $TEMP | cut -d: -f2 | xargs echo)
access_token=$(grep "token" $TEMP | cut -d: -f2 | xargs echo)
access_token_secret=$(grep "secret:" $TEMP | tail -1 | cut -d: -f2 | xargs echo)
username=$(grep "username" $TEMP | tail -1 | cut -d: -f2 | xargs echo)
mashape_key=$(cat ~/.mashapekey)

cat <<EOF > $PYTEMP
#!/bin/python
import botometer

mashape_key = "$mashape_key"
twitter_app_auth = {
      'consumer_key': '$consumer_key',
      'consumer_secret': '$consumer_secret',
      'access_token': '$access_token',
      'access_token_secret': '$access_token_secret'
}
bom = botometer.Botometer(mashape_key=mashape_key, **twitter_app_auth)

# Check a single account
result = bom.check_account('@$username')

print(result)
EOF

BOTSCOREENG=""
BOTSCOREUNI=""
until [[ $BOTSCOREENG -gt 0 ]]; do
    IFS=, read -a values <<< $(python $PYTEMP | cut -d"{" -f5 | sed -e "s/[a-z:' }]//g")
    BOTSCOREENG=$(bc -l <<< "${values[0]} * 100" | cut -d. -f1)
    BOTSCOREUNI=$(bc -l <<< "${values[1]} * 100" | cut -d. -f1)
done
t update "My bot score according to Botometer (botometer.iuni.iu.edu) is $BOTSCOREENG%, ignoring the english specific stuff it is $BOTSCOREUNI%. Have a nice day."
