#!/bin/bash
# Shuf a list of words from eschalots wordlists into a seeded random order
# get seeded random was lifted from https://stackoverflow.com/questions/5914513/shuffling-lines-of-a-file-with-a-fixed-seed
get_seeded_random()
{
    seed="$1"
    openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt \
        </dev/zero 2>/dev/null
}
cat eschalot/nouns.txt eschalot/top400nouns.txt eschalot/top150adjectives.txt \
    | sort \
    | uniq \
    | shuf --random-source=<(get_seeded_random 20180420) > word.list
