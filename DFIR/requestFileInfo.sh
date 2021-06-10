#!/bin/bash
# requestFileInfo.sh
# collect information about a specified file (Linux)
# Last Edited: 06/10/2021 Julian Thies
# 
# 
# User will have to decide how to get the tar.gz off of the system


### VARIABLES
suspFile="$1"
resultsDir="$(pwd)/RequestResults"
resultsArchiveName="RequestResults"

# transform filename - replace "/" with "_"
transform="$(echo "$1" | sed -r 's/[/]+/_/g')"
transform1="$(echo "$transform" | sed -r 's/[.]+/-/g')"

destFile="$resultsDir/FileInfo_$transform1.txt"
bhDir="$resultsDir/bh"


### FUNCTIONS
function declare_script {
	echo
	echo "[ ========== $0 ========== ]"
	echo "Script to collect information about a specific file and some other"
	echo "useful information from the system for light forensic analysis"
	echo
	echo "results will show up in $resultsDir"
	echo
	echo "You can query multiple files and multiple results files will be added"
	echo
	echo "[ ========== $0 ========== ]"
	echo
}

function check_user {
	if [ "$(whoami)" != "root" ] ; then
		echo "Must be run with root privileges"
		exit
	fi
}

# function to add a newline in between sections of the results file
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
	section_header "HASHES"
	echo "sha256:  $(shasum -a 256 $suspFile | awk '{print $1}')" >> "$destFile"
	echo "   md5:  $(md5sum $suspFile | awk '{print $1}')" >> "$destFile"
	echo "  sha1:  $(shasum $suspFile | awk '{print $1}')" >> "$destFile"
	space
}

function file_type {
	section_header "FILETYPE"
	file "$suspFile" >> "$destFile"
	space
}

function file_owner {
	section_header "FILE OWNER"
	echo "Owner username: $(stat -c %U "$suspFile")" >> "$destFile"
	echo "Owner UID: $(stat -c %u "$suspFile")" >> "$destFile"
	echo "Owner Groupname: $(stat -c %G "$suspFile")" >> "$destFile"
	echo "Owner GID: $(stat -c %g "$suspFile")" >> "$destFile"
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

function recent_logins {
	section_header "RECENT LOGINS"
	last >> "$destFile"
	space
}

function cp_bash_history {
	section_header "BASH HISTORY"
	echo "Review Bash History files in bh directory" >> "$destFile"

	# get all potential bash history files
	if [ ! -d "$bhDir" ] ; then
		mkdir "$bhDir"
	fi
	
	# make array of possible home directories
	HomeDirArray=()
	HomeDirArray+=($(getent passwd | cut -d: -f6))
	
	# for each entry in the array cp the .bash history file,
	#+and rename the file to BASH_HISTORY_home_username.txt
	for (( i=0; i<${#HomeDirArray[@]}; i++ )) ; 
	do
		homeDir="${HomeDirArray[$i]}"
		
		if [ -f "$homeDir/.bash_history" ] ; then
			echo "Copying $homeDir/.bash_history to $bhDir" >> "$destFile"
			
			# transform name of home dir - replace "/" with "_"
			homeDirSlashReplace="$(echo "$homeDir" | sed -r 's/[/]+/_/g')"
			BHName="BASH_HISTORY$homeDirSlashReplace.txt"
			
			cp "$homeDir/.bash_history" "$bhDir/$BHName"

		fi
	done
		
	# cp root bash history if it exists
	if [ -f /root/.bash_history ] ; then
		echo "Copying /root/.bash_history to $bhDir/BASH_HISTORY_root.txt"
		cp /root/.bash_history "$bhDir/BASH_HISTORY_root.txt"
	else
		echo "No Root Bash History" >> "$destFile"
	fi	
	space
}

function process_list {
	echo "$(ps axjf)" >> "$resultsDir/$(date +%y-%m-%d_%H-%M-%S)_PS_tree.txt"
	echo "$(netstat -peanutw)" >> "$resultsDir/$(date +%y-%m-%d_%H-%M-%S)_NETSTAT.txt"
}

function cp_syslog {
	section_header "SYSLOG COLLECTION"
	
	if [ -f /var/log/syslog ] ; then
		# check if syslog already copied in the case of running the script against multiple files
		if [ -f "$resultsDir/syslog" ] ; then
			echo "Syslog already there" >> "$destFile"
		else
			cp /var/log/syslog "$resultsDir"
		fi
		
	else
		echo "Error: Syslog not in /var/log/syslog" >> "$destFile"
	fi
	space
}

function tar_results {
	section_header "TAR CREATION"
	echo "Generating tar.gz archive of results"
	cd $(pwd)
	tar -czvf "$resultsArchiveName.tar.gz" --hard-dereference --dereference "$resultsDir" 2>&1 "$destFile"
}


### SCRIPT
declare_script
check_user

# make our results directory if we need to
if [ ! -d $resultsDir ] ; then
	mkdir "$resultsDir"
fi

# check if the file is still there
if [ ! -e "$1" ] ; then
	echo "$1"
	echo "Error: No file submitted"
	exit
else
	if [ -e "$1" ] ; then
		echo "Gathering file information"
	else
		echo "Requested file does not exist"
		exit
	fi
fi

# file ops on requested file
file_header
file_hashes
file_type
file_owner
file_stats
file_strings
ip_strings
file_processes
recent_logins

# general information collection
process_list
cp_bash_history
cp_syslog
tar_results

