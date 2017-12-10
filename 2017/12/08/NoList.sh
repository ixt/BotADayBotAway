#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

# Basically makes a list of users who have "No lists" in their bio.
# https://twitter.com/DLStauffer/status/937511654777954304
SCRIPTDIR=$(dirname $0)
TEMP=$(mktemp)
TEMPUSER=$(mktemp)
SOURCE=$(mktemp)
SCRIPT=$(mktemp)
URL="https://mobile.twitter.com/search/users?q=NO%20LISTS&s=typd"

COUNT="0"
# https://developer.mozilla.org/en-US/Firefox/Headless_mode#Automated_testing_with_headless_mode
cat <<EOF > $SCRIPT
import sys
import codecs
from selenium.webdriver import Firefox
from selenium.webdriver import FirefoxProfile
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support import expected_conditions as expected
from selenium.webdriver.support.wait import WebDriverWait

if __name__ == "__main__":
    f = codecs.open(sys.argv[2], "w", "utf-8")
    options = Options()
    options.add_argument('-headless')
    profile = FirefoxProfile("/home/orange/.mozilla/firefox/7qefm09p.default")
    driver = Firefox(executable_path='./geckodriver', firefox_options=options, firefox_profile=profile)
    wait = WebDriverWait(driver, timeout=1)
    driver.get(sys.argv[1])
    f.write(driver.page_source)
    f.close()
    driver.quit()
EOF

pushd $SCRIPTDIR 

while true; do
    echo "[*]: Getting search $(( COUNT += 1))"
    python $SCRIPT "$URL" "$SOURCE" 
    grep href $SOURCE | cut -d'"' -f 2 | grep "^/" | uniq > $TEMP
    
    while read USER; do
        
        if ! grep "^${USER}$" .USERS; then
        echo "[*]: Getting User"
        wget -qO- "https://twitter.com${USER}" |\
            grep "\"description\" content=" |\
            sed -e "s/  <meta name=\"description\" content=\"//g" -e "s/\">$//g" |\
            grep -i "no lists" 
            if [ "0" -eq "$?" ]; then
                echo $USER | tee -a .USERS
            fi
        fi
    
    done < <(grep "?p=" $TEMP | sed -e "s/?.*//g")
    
    if grep -q "search" $TEMP; then
        URL="https://mobile.twitter.com$(grep "search" $TEMP)"
    else 
        cat $TEMP
        echo $URL
        exit 0
    fi

    echo "[*]: Waiting 3s"
    sleep 3s
done

popd

