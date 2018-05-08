#!/bin/bash
# Shuf a list of words from eschalots wordlists into a seeded random order
# get seeded random was lifted from https://stackoverflow.com/questions/5914513/shuffling-lines-of-a-file-with-a-fixed-seed
get_seeded_random()
{
    seed="$1"
    openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt \
        </dev/zero 2>/dev/null
}
cat ../20/eschalot/nouns.txt ../20/eschalot/top400nouns.txt ../20/eschalot/top150adjectives.txt \
    | sort \
    | uniq \
    | shuf --random-source=<(get_seeded_random 20180420) > word.list

# Probably a better way, who cares!
tac word.list > new.list 
mv new.list word.list

