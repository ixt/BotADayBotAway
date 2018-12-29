#!/bin/bash
NAME=".[] | select(.name | test(\"^${1}$\"))"
jq "${NAME}" Permissions.json 

