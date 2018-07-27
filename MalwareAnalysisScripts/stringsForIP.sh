#!/bin/bash
# stringsForIP.sh
# strings for IP addresses
# Last Edited: 6/22/18 Julian Thies

# check if anything is passed in
if [ -z "$1" ] ; then
	echo "No file passed in"
else
	# a rough grep for IP addresses
	strings "$1" | grep -wn '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sort | uniq -u
fi
