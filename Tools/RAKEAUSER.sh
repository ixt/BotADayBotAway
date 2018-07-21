#!/bin/bash
USERID=$1
pushd $(dirname $0)
    ./RAKE.sh/RAKE.sh \
        <(./GETALLOFAUSER.sh $USERID \
            | jq -r .docs[][] \
            | sed "s@https://[\.a-zA-Z0-9/]*@@g;s/@[^ ]* //g" \
            )
popd
