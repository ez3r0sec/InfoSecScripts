#!/bin/bash
# requestFileInfo.sh
# collect information about a specified file (Linux)
# Last Edited: 06/15/2021 Julian Thies
# 
# use to get information about a suspicious file on a Linux system
# tested on Ubuntu
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

function check_sus_file_exists () {
	if [ -e "$1" ] ; then
		echo "$1 exists, proceeding with data collection"
	else
		echo "$1 does not exist, exiting"
		exit
	fi
}

function mk_results_dir () {
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

function root_bash_history {
	section_header "SHELL HISTORY"
	
	# cp root bash history if it exists
	if [ -f /root/.bash_history ] ; then
		echo "Copying /root/.bash_history to $bhDir/BASH_HISTORY_root.txt"
		cp /root/.bash_history "$bhDir/BASH_HISTORY_root.txt"
	else
		echo "No Root Bash History" >> "$destFile"
	fi	
	space
}

# called by loop_home_dirs
function cp_shell_history () {
	# get all potential bash history files
	if [ ! -d "$bhDir" ] ; then
		mkdir "$bhDir"
	fi

	# parse our function input
	homeDir="$1"
	
	# transform name of home dir - replace "/" with "_"
	homeDirSlashReplace="$(echo "$homeDir" | sed -r 's/[/]+/_/g')"
		
	### BASH 
	if [ -f "$homeDir/.bash_history" ] ; then
		echo "Copying $homeDir/.bash_history to $bhDir" >> "$destFile"
			
		# define name of dest file
		BHName="BASH_HISTORY$homeDirSlashReplace.txt"
			
		# copy to the new file in the RequestResults directory
		cp "$homeDir/.bash_history" "$bhDir/$BHName"
	else
		echo "$homeDir/.bash_history not found" >> "$destFile"
	fi
		
	### PYTHON collect python history
	if [ -f "$homeDir/.python_history" ] ; then
		echo "Copying $homeDir/.python_history to $bhDir" >> "$destFile"
			
		PHName="PYTHON_HISTORY$homeDirSlashReplace.txt"
			
		cp "$homeDir/.python_history" "$bhDir/$PHName"
	else
		echo "$homeDir/.python_history not found" >> "$destFile"
	fi
		
	### SQLITE collect sqlite history if present
	if [ -f "$homeDir/.sqlite_history" ] ; then
		echo "Copying $homeDir/.sqlite_history to $bhDir" >> "$destFile"
			
		SqHName="SQLITE_HISTORY$homeDirSlashReplace.txt"
			
		cp "$homeDir/.sqlite_history" "$bhDir/$SqHName"
	else
		echo "$homeDir/.sqlite_history not found" >> "$destFile"	
	fi
}

# called by loop_home_dirs
function ssh_info () {
	space
	# transform name of home dir - replace "/" with "_"
	homeDirSlashReplace="$(echo "$1" | sed -r 's/[/]+/_/g')"
	if [ -f "$homeDir/.ssh/known_hosts" ] ; then
		echo "Copying contents of $homeDir/.ssh/known_hosts $destFile" >> "$destFile"
		section_header "SSH INFO"
		space
		echo "$homeDirSlashReplace"
		echo "$(cat "$homeDir/.ssh/known_hosts")" >> "$destFile"
		space
	else
		echo "$homeDir/.ssh/known_hosts file not found" >> "$destFile"
	fi
}

# calls shell history and ssh info functions
function loop_home_dirs {
	# make array of possible home directories
	HomeDirArray=()
	HomeDirArray+=($(getent passwd | cut -d: -f6))
	
	# for each entry in the array cp the .bash history file,
	#+and rename the file to BASH_HISTORY_home_username.txt
	for (( i=0; i<${#HomeDirArray[@]}; i++ )) ; 
	do
		homeDir="${HomeDirArray[$i]}"
		
		# pass homeDir into shell history and ssh info functions
		cp_shell_history "$homeDir"
		ssh_info "$homeDir"
	done
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

function cp_ufw_log {
	section_header "UFW COLLECTION"
	
	if [ -f /var/log/ufw.log ] ; then
		echo "UFW Log found in /var/log, copying"
		
		# if ufw conf file exists, grab some info from it
		if [ -f /etc/ufw/ufw.conf ] ; then
			echo "UFW: $(cat /etc/ufw/ufw.conf | grep "ENABLED")" >> "$destFile"
			echo "UFW: $(cat /etc/ufw/ufw.conf | grep "LOGLEVEL")" >> "$destFile"
		else
			echo "Error: UFW conf file /etc/ufw.ufw.conf does not exist" >> "$destFile"
		fi
		
		# if the uwf.log is already in the results directory, just copy ufw.log and not the additional archives of logs
		if [ -f "$resultsDir/uwf.log" ] ; then
			cp /var/log/ufw.log "$resultsDir"
		else
			cp /var/log/ufw.log* "$resultsDir"
		fi
	else
		echo "UFW Log not found" >> "$destFile"
	fi
	space
}

function cp_auth_log {
	section_header "AUTH.LOG COLLECTION"

	if [ -f /var/log/auth.log ] ; then
		if [ -f "$resultsDir/auth.log" ] ; then
			cp /var/log/auth.log "$resultsDir"
		else
			cp /var/log/auth.log* "$resultsDir"
		fi
	else
		echo "Error: auth.log not found in /var/log" >> "$destFile"
	fi
	space
}

function tar_results {
	section_header "TAR CREATION"
	echo "Generating tar.gz archive of results"
	echo
	cd $(pwd)
	tar -czvf "$resultsArchiveName.tar.gz" --hard-dereference --dereference "$resultsDir" 2>&1 "$destFile"
}


### SCRIPT
declare_script
check_user
check_sus_file_exists "$1"

mk_results_dir "$1"

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
root_bash_history
loop_home_dirs
cp_syslog
cp_ufw_log
cp_auth_log
tar_results

echo
echo "Information collection complete!"

