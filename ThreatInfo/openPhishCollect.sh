#!/bin/bash
# openPhishCollect.sh
# collect domains from https://openphish.com/feed.txt
# Last Edited: 5/11/17

### VARIABLES
userName="$(id -un)"

URL="https://openphish.com/feed.txt"
feedFile="/home/$userName/Desktop/phishFeed.txt"

### SCRIPT
curl -s -o "$feedFile" "$URL"
