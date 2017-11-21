#!/bin/bash
DAYSINMONTH=( 31 29 31 30 31 30 31 31 30 31 30 31 )
MONTHS=( "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December" )
DAYS=( "0th" "1st" "2nd" "3rd" "4th" "5th" "6th" "7th" "8th" "9th" "10th" "11th" "12th" "13th" "14th" "15th" "16th" "17th" "18th" "19th" "20th" "21st" "22nd" "23rd" "24th" "25th" "26th" "27th" "28th" "29th" "30th" "31st" )

for i in $(seq 0 11); do
    for j in $(seq 1 ${DAYSINMONTH[$i]}); do
        date=$(echo "${MONTHS[$i]} the ${DAYS[$j]}")
        ID=$(lynx -dump -listonly "https://twitter.com/search?f=tweets&q=from%3Amode7games $date" | grep "/status/" | cut -d" " -f3 | tail -n-1 | cut -d"/" -f6 )
        echo "$date,$ID" | tee -a ListOfTweets
        ../../../Tools/tweet.sh/tweet.sh fetch $ID | jq .text
    done
done

# I then went through and fixed a few that were too far from the intention
