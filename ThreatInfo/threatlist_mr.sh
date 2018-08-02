#!/bin/bash
# threatlist_mr.sh
# http://matthewroberts.io/api/threatlist/latest
# Last Edited: 8/2/18 Julian Thies

### VARIABLES
userName="$(id -un)"
URL="https://www.binarydefense.com/banlist.txt"
tmpFile="/tmp/list.txt"
listFile="/home/$userName/Desktop/mattroberts_threatlist.txt"

### FUNCTIONS
function dl_list {
	curl -o "$tmpFile" "$URL"
}

function clean_up {
	if [ -e "$tmpFile" ] ; then
		rm "$tmpFile"
	fi
}

### SCRIPT
dl_list
clean_up
