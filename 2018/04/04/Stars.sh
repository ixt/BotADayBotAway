#!/bin/bash
ID1=$(twurl -H upload.twitter.com "/1.1/media/upload.json" -f $1 -F media -X POST | jq -r .media_id_string) 
echo $ID1

twurl "/1.1/statuses/update.json" -d "media_ids=$ID1&status=･ ｡
 ☆∴｡　*
　･ﾟ*｡★･
　　･ *ﾟ｡　　 *
　 ･ ﾟ*｡･ﾟ★｡
　　　☆ﾟ･｡°*. ﾟ
*　　ﾟ｡·*･｡ ﾟ*
　　　ﾟ *.｡☆｡★　･
　　* ☆ ｡･ﾟ*.｡
　　　 *　★ ﾟ･｡ *  ｡
　　　　･　　ﾟ☆ ｡"
