#!/bin/bash
# openPhishCollect.sh
# collect domains from https://openphish.com/feed.txt
# Last Edited: 10/17/17

userName="$(id -un)"

URL="https://openphish.com/feed.txt"
feedFile="/home/$userName/Desktop/phishFeed.txt"

curl -s -o "$feedFile" "$URL"
