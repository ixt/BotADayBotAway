#!/bin/bash
# If it doesnt work then do it again
Notworking=1
while [[ $Notworking -gt "0" ]]; do
	$@
	Notworking="$?"
done
