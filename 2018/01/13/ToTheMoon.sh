#!/bin/bash
# https://twitter.com/TehJoeCow/status/985642424784642048
# take a screen shot of the current 24h bitcoin chart, if up 300 usd then post
# saying the market is being manipulated, if it drops say the bubble is popping

# TODO:
# [ ]: Screenshot a relevant chart
# [ ]: Decide on a bot name 
# [ ]: Decide on a frequency, 1 day? 12 hours? 6 hours? 3 hours?

echo "Currently do nothing, work in progress" 
exit 0

checkPrice(){
    CURRENTPRICE=$(curl "https://blockchain.info/tobtc?currency=USD&value=1" | xargs -I@ echo " 1 / @ " | bc -l )
}

width="300"
height="1000"
SCRIPTDIR=$(dirname $0)
SCREENSHOT=$(mktemp --suffix=.png)
TEMP=$(mktemp)
twelveHoursAgo=$(date --date="- 12 hours" +%s)

screenshot(){
    # We repeat this 4 times just to make it takes it 
    fileSize="0"
    echo "[INFO]: Screenshot"
    while [ "${fileSize}" -lt "20000" ]; do
        if [ -e "/usr/bin/chromium" ]; then
        chromium --headless --disable-gpu $1 --hide-scrollbars --virtual-time-budget=20170120 --window-size=${width},${height} --force-device-scale-factor=2 --hide-scroll-bars --screenshot=${SCREENSHOT}
        else
        chromium-browser --headless --disable-gpu $1 --hide-scrollbars --virtual-time-budget=20170120 --window-size=${width},${height} --force-device-scale-factor=2 --hide-scroll-bars --screenshot=${SCREENSHOT}
        fi
        fileSize=$(ls -l ${SCREENSHOT} | cut -d" " -f5)
    done
}

pushd $SCRIPTDIR 

read LASTPRICE < lastPrice 

DIFFERENCE=$(bc -l <<< "$LASTPRICE - $CURRENTPRICE")

if [[ $DIFFERENCE -gt 300 || $DIFFERENCE -lt -300 ]]; then
    screenshot

    #t update " " -f output.png
    display output.png
fi

echo "$CURRENTPRICE" > lastPrice
popd
