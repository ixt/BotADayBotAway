#!/bin/bash
# https://twitter.com/TwoBitPirate/status/976463377001312256
# A bot that tweets the current exchange rate for 1 XMR in BTC
CURRENT=$(curl "https://api.coinmarketcap.com/v1/ticker/monero/" | jq -r .[].price_btc )
t update "A \$XMR is worth $CURRENT BTC" -P ~/.trc.monero
