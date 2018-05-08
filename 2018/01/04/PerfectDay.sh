#!/bin/bash
# Perfect day according to https://www.outsideonline.com/2142236/perfect-day
set -euo pipefail
IFS=$'\n\t'
TEMP=$(mktemp)
curl "https://api.sunrise-sunset.org/json?lat=51.509865&lng=-0.118092" > $TEMP
SCRIPTDIR=$(dirname $0)
SUNRISE=$(jq -r .results.sunrise $TEMP | cut -d: -f1-2)
pushd $SCRIPTDIR 
at -f WakingUp.sh "$SUNRISE"
at -f DontShower.sh "$SUNRISE + 10 minutes"
at -f CoffeeAndBreakfast.sh "$SUNRISE + 15 minutes"
at -f GetMoving.sh "08:00"
at -f StartWorking.sh "09:00"
at -f TakeABreak.sh "09:10"
at -f HaveASnack.sh "09:30"
at -f CheckEmail.sh "09:50"
at -f AnotherSnack.sh "10:40"
at -f VISUALIZE.sh "11:00"
at -f LUNCHTIME.sh "12:30"
at -f TeaBreak.sh "13:30"
at -f CallMom.sh "16:45"
at -f CheckEmailAndMakeAList.sh "17:05"
at -f Workout.sh "18:00"
at -f Slowdown.sh "18:35"
at -f Shower.sh "19:15"
at -f Unwind.sh "19:30"
at -f OneWontHurt.sh "19:35"
at -f News.sh "20:45"
at -f GoodbyeScreens.sh "21:00"
at -f GoToBed.sh "22:00"
at -f Attribution.sh "23:00"
popd
