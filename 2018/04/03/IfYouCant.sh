#!/bin/bash

# twurl -H upload.twitter.com "/1.1/media/upload.json" -f $1 -F media -X POST | jq .
# twurl -H upload.twitter.com "/1.1/media/upload.json" -f $2 -F media -X POST | jq .
ID1=$(twurl -H upload.twitter.com "/1.1/media/upload.json" -f $1 -F media -X POST | jq -r .media_id_string) 
echo $ID1
ID2=$(twurl -H upload.twitter.com "/1.1/media/upload.json" -f $2 -F media -X POST | jq -r .media_id_string) 
echo $ID2

twurl "/1.1/statuses/update.json" -d "media_ids=$ID1,$ID2&status=if you cant                         you don't
handle me                         deserve me
at my                                  at my "
