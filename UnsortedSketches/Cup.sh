#!/bin/bash
CURRENTTIME=$(date +%Y-%m-%d-%H-%M)
fswebcam --no-overlay --no-banner -S 100 -r 1920x1080 --save ~/cups/$CURRENTTIME.jpg \
    && t set profile_image ~/cups/$CURRENTTIME.jpg \
    && t update -f ~/cups/$CURRENTTIME.jpg "$CURRENTTIME #DreherTweet2"
