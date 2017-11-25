#!/bin/bash
SCRIPTDIR=$(dirname $0)
pushd $SCRIPTDIR 
wget http://www.script-o-rama.com/movie_scripts/a1/bee-movie-script-transcript-seinfeld.html 
START=$(grep -n "<pre>" bee-movie-script-transcript-seinfeld.html | cut -d":" -f1)
sed -i 1,${START}d bee-movie-script-transcript-seinfeld.html
sed -i "/^\s*$/d" bee-movie-script-transcript-seinfeld.html
END=$(grep -n "</pre>" bee-movie-script-transcript-seinfeld.html | cut -d":" -f1)
head -$(( END - 1 )) bee-movie-script-transcript-seinfeld.html > .lines
sed -i "s/^-\(.*\)$/«\1 »/p" .lines
rm bee-movie-script-transcript-seinfeld.html
popd
