#!/bin/bash 
twurl -X POST /1.1/statuses/unretweet/$1.json
twurl -X POST /1.1/statuses/retweet/$1.json

