#!/bin/bash
# banlist_BDSA.sh
# hxxps://www.binarydefense[.]com/banlist.txt
# Last Edited: 8/2/18 Julian Thies

### VARIABLES
userName="$(id -un)"
URL="https://www.binarydefense.com/banlist.txt"
tmpFile="/tmp/list.txt"
listFile="/home/$userName/Desktop/binarydefense_banlist.txt"

### FUNCTIONS
function dl_list {
	curl -o "$tmpFile" "$URL"
}

function process_list {
	grep -v "#" "$tmpFile" >> "$listFile"
}

function clean_up {
	if [ -e "$tmpFile" ] ; then
		rm "$tmpFile"
	fi
}

### SCRIPT
dl_list
process_list
clean_up
