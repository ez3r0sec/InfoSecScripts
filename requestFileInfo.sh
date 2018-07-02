#!/bin/bash
# requestFileInfo.sh
# collect information about a specified file (Linux)
# Last Edited: 7/2/18 Julian Thies

### VARIABLES
suspFile="$1"
destFile="/tmp/FileInfo.txt"

### FUNCTIONS
function check_user {
	if [ "$(whoami)" != "root" ] ; then
		echo "Must be run with root privileges"
		exit
	fi
}

function check_input {
	if [ -z "$1" ] ; then
		echo "No file submitted"
		exit
	else
		if [ -e "$1" ] ; then
			echo "Gathering file information"
		else
			echo "Requested file does not exist"
			exit
		fi
	fi
}

function space {
	echo >> "$destFile"
}

function section_header () {
	inputString="$1"
	echo "[ === $inputString ===]" >> "$destFile"
}

# GENERATE FILE
# file header
function file_header {
	echo "[ === $(date) -- $(hostname) -- FileInfo: $suspFile === ]" > "$destFile"
	space
}

function file_hashes {
	section_header "HASH"
	echo "sha256:  $(shasum -a 256 $suspFile | awk '{print $1}')" >> "$destFile"
	echo "md5   :  $(md5sum $suspFile | awk '{print $1}')" >> "$destFile"
	echo "sha1  :  $(shasum $suspFile | awk '{print $1}')" >> "$destFile"
	space
}

function file_type {
	section_header "FILE"
	file "$suspFile" >> "$destFile"
	space
}

function file_size {
	section_header "FILE SIZE KB"
	file_size_kb="$(du -k "$suspFile" | cut -f1)"
	echo "$file_size_kb" >> "$destFile"
	space
}

function file_strings {
	section_header "STRINGS"
	strings "$suspFile" >> "$destFile"
	space
}

function ip_strings {
	section_header "STRINGS FOR IP"
	strings "$suspFile" | grep -w '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sort | uniq -u >> "$destFile"
	space
}

function file_stats {
	section_header "STAT"
	stat "$suspFile" >> "$destFile"
	space
}

function file_processes {
	section_header "PROCESSES RELATED TO $suspFile"
	ps auxwZ | grep '$suspFile' >> "$destFile"
	space
}

### SCRIPT
check_user
check_input
file_header
file_hashes
file_type
file_size
file_strings
ip_strings
file_stats
file_processes