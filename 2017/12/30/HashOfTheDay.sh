#!/bin/bash
set -euo pipefail
# Tweets out the hash of todays date using 4 different hashing algos
SHA1=$(date +%Y%m%d | sha1sum | cut -d" " -f1)
MD5=$(date +%Y%m%d | md5sum | cut -d" " -f1)
SHA256=$(date +%Y%m%d | sha256sum | cut -d" " -f1)
SHA384=$(date +%Y%m%d | sha384sum | cut -d" " -f1)
twurl -d "status=The SHA1 Hash of the day: 
$SHA1
" /1.1/statuses/update.json
sleep 1s
twurl -d "status=The MD5 Hash of the day: 
$MD5
" /1.1/statuses/update.json
sleep 5s
twurl -d "status=The SHA256 Hash of the day: 
$SHA256
" /1.1/statuses/update.json
sleep 25s
twurl -d "status=The SHA384 Hash of the day: 
$SHA384
" /1.1/statuses/update.json
