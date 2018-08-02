#!/bin/bash
# whoisList.sh
# get the geolocation and reg info for ips and output to CSV
# Last Edited: 7/15/18 Julian Thies

### VARIABLES
resultsFile="$(pwd)/whoisList_results.csv"
ipFile=

### FUNCTIONS
# check that a list of IPs was passed in
function check_list () {
	if [ -z "$1" ] ; then
		echo "Please pass in a list of IP addresses to investigate"
		exit
	else
		if [ "$(file $1 | awk '{print $2}')" == "ASCII" ] ; then
			echo "File appears to be the proper file type, running..."
			ipFile="$1"
		else
			echo "File does not appear to be the proper file type (ASCII text), exiting"
			exit
		fi
	fi
}

# read the file and go line by line
function process_file {
	cat "$ipFile" | while read line
	do
		IPADDR="$line"	
		# info we are collecting (best effort only, not all records contain ASN for example)
		ASN="$(whois $IPADDR | grep 'origin' | awk '{print $2}')"
		COUNTRY="$(whois $IPADDR | grep 'Country' -m 1 | awk '{print $2}')"
		REGDATE="$(whois $IPADDR | grep 'RegDate' -m 1 | awk '{print $2}')"
		# write out info to file	
		echo "$IPADDR,$ASN,$COUNTRY,$REGDATE" >> "$resultsFile"
	done
}

### SCRIPT
check_list "$1"
process_file
