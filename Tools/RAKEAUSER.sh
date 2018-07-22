#!/bin/bash
USERID=$1
pushd $(dirname $0) > /dev/null
    ./RAKE.sh/RAKE.sh \
        <(./GETALLOFAUSER.sh $USERID \
            | jq -r .docs[][] \
            | sort \
            | uniq \
            | sed -e "s@https://[\.a-zA-Z0-9/]*@@g" \
                  -e "s/@[^ ]* //g" \
            )
popd > /dev/null
