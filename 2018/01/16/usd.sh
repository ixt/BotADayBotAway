#!/bin/bash
# Compare the tethered currencies
CURRENTUSDT=$(curl "https://api.coinmarketcap.com/v1/ticker/tether/" | jq -r .[].price_usd )
CURRENTTUSD=$(curl "https://api.coinmarketcap.com/v1/ticker/true-usd/" | jq -r .[].price_usd )
t update "1 \$USD is worth $CURRENTTUSD \$TUSD & $CURRENTUSDT \$USDT" -P ~/.trc.usd
