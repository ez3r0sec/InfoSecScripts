#!/bin/bash
# BRIP_ThreatList.sh
# hxxp://www.neblink[.]net/blocklist/IP-Blocklist.txt
# Last Edited: 8/2/18 Julian Thies

### VARIABLES
userName="$(id -un)"
URL="http://www.neblink.net/blocklist/IP-Blocklist.txt"
tmpFile="/tmp/list.txt"
listFile="/home/$userName/Desktop/DRIP_ThreatList.txt"

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
