#!/bin/bash
# sysInfoCollect.sh
# basic live system information gathering for linux
# Last Edited: 3/5/2021 Julian Thies

##### variables
starDate="$(date)"
ymdDate="$(date +%y-%m-%d)"
hostName="$(hostname)"
userName="$(id -un)"

destDir="/usr/local/var/$ymdDate-SysInfoCollect"
destFile="$destDir/sysInfoResults.txt"

# param 1 is a file with full path to investigate
param1="$1"

##### functions
function space {
	echo "-----------------------------------------" >> "$destFile"
	echo >> "$destFile"
}

function sect_head () {
	if [ -z "$1" ] ; then
		echo "EMPTY SECTION HEADER" >> "$destFile"
	else
		echo "=============== $1" >> "$destFile"
	fi
}

function check_root {
	if [ "$userName" != "root" ] ; then
		echo "Script must be run as root!"
		exit
	else
		echo "Happy forensicating!"
	fi
}

function mk_collection_dir {
    ### set up a collection bin
    # make a home for the analysis files
    if [ -e "$destDir" ] ; then
	    rm -r "$destDir"
		mkdir -p "$destDir"
	    chown -R "$userName" "$destDir"
    else
	    mkdir -p "$destDir"
	    chown -R "$userName" "$destDir"
    fi
}

function out_file_header {
    ### output file header
	destFile="$destDir/sysInfoResults.txt"
    echo "[ --- System Information --- $starDate --- $hostName --- ]" > "$destFile"
	sha256Script="$(shasum -a 256 "$0" | awk '{print $1}')"
	echo "Script hash: $sha256Script" >> "$destFile"
	echo "User: $(id -un)" >> "$destFile"
	echo "===== System version info" >> "$destFile"
    cat /etc/*-release >> "$destFile"
    echo "===== Timezone information" >> "$destFile"
    timedatectl >> "$destFile"
    echo "===== Approximate system install time:" >> "$destFile"
    stat /etc/ssh/ssh_host_ecdsa_key | grep 'Modify' >> "$destFile"
    echo "===== Hosts file" >> "$destFile"
    cat /etc/hosts >> "$destFile"
    space
}

########## file info request section
function section_header () {
	inputString="$1"
	echo "[ === $inputString ===]" >> "$destFile"
}

function request_file_info () {
	destFile="$destDir/RequestFileInfoResults.txt"
	if [ -z "$1" ] ; then
		echo "No file path passed in" >> "$destFile"
	else
		echo "Collecting info about $1"
		suspFile="$1"
		if [ -e "$suspFile" ] ; then
			### GENERATE FILE
			# file header
			echo "[ === $(date) -- $(hostname) -- FileInfo: $suspFile === ]" > "$destFile"
			echo >> "$destFile"
			# hash the file
			section_header "HASH"
			echo "sha256:  $(shasum -a 256 $hashFile | awk '{print $1}')" >> "$destFile"
			echo "md5   :  $(md5sum $hashFile | awk '{print $1}')" >> "$destFile"
			echo "sha1  :  $(shasum $hashFile | awk '{print $1}')" >> "$destFile"
			echo >> "$destFile"
			# file information
			section_header "FILE"
			file "$suspFile" >> "$destFile"
			echo >> "$destFile"
			# stat file
			section_header "STAT"
			stat "$suspFile" >> "$destFile"
			echo >> "$destFile"
			# get the file size
			section_header "FILE SIZE KB"
			file_size_kb="$(du -k "$suspFile" | cut -f1)"
			echo "$file_size_kb" >> "$destFile"
			echo >> "$destFile"
			# strings the file
			section_header "STRINGS"
			strings "$suspFile" >> "$destFile"
			echo >> "$destFile"
			# look for IP addresses
			section_header "STRINGS FOR IP"
			strings "$suspFile" | grep -w '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sort | uniq -u >> "$destFile"
		else
			echo "$suspFile is not on disk" >> "$destFile"
		fi
	fi
}
##########

function mounted_fs {
	destFile="$destDir/sysInfoResults.txt"
	sect_head "MOUNTED FILESYSTEMS"
	echo "===== df -aTH" >> "$destFile"
	df -aTH >> "$destFile"
	space
}

function process_ops {
	echo "Collecting processes information"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "PROCESS INFO"
    ### collect process info
    # sorted by highest PID to lowest
    echo "===== ps auxwf (sorted by PID)" >> "$destFile"
    ps auxwf | sort -n -k 2,2 >> "$destFile"

	# look for processes running out of /dev
	ps auxwf | grep '/dev' | grep -v 'grep' >> "$destFile"
	# remove the file if it is empty
	numLines="$(wc -l < "$destFile")"
	if [ "$numLines" -eq 0 ] ; then
		rm "$destFile"
	fi
	space
}

function raw_sockets {
	destFile="$destDir/sysInfoResults.txt"
	rawSocks="$(netstat -nalp | grep 'raw')"
	if [ "$rawSocks" != "" ] ; then
		echo "===== RAW Socket detected" >> "$destFile"
        echo "$rawSocks" >> "$destFile"
    fi
}

function network_ops {
	echo "Collecting networking information"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "NETWORK INFO"
    ### ifconfig
    echo "===== ifconfig" >> "$destFile"
    ifconfig >> "$destFile"
    space

    ### collect all port/network info
    echo "===== netstat -nalp" >> "$destFile"
    netstat -nalp >> "$destFile"
	echo >> "$destFile"
    ### look for raw sockets
    raw_sockets
    space
}

function find_exes () {
	destFile="$destDir/sysInfoResults.txt"
	if [ -z "$1" ] ; then
		echo "No param 1 passed in" >> "$destFile"
	else
		find "$1" -type f -executable >> "/tmp/ex.txt"
	fi
}

function file_ops {
	echo "Collecting information about files on disk"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "FILE INFO"
	### see if there are any 'deleted' files in proc
	echo "===== ls -la /proc | grep 'deleted'  {Deleted in /proc}" >> "$destFile"
	deleted="$(ls -la /proc | grep 'deleted')"
	if [ "$deleted" != "" ] ; then
		echo "$deleted" >> "$destFile"
		# pull the PID
		ls -la /proc | grep 'deleted' | awk '{print $9}' >> "/tmp/pids.txt"
		cat /tmp/pids.txt | while read line
		do
			mkdir "/tmp/$line"
			# carve the executable file from /proc/$PID/exe
			cp "/proc/$line/exe" "/tmp/$line/"
			# hash the file
			sha256="$(shasum -a 256 "/tmp/$line/exe" | awk '{print $1}')"
			md5sum="$(md5sum "/tmp/$line/exe" | awk '{print $1}')"
			echo "PID: $line -->  SHA256: $sha256  MD5: $md5sum" >> "$destFile"
			stat "/tmp/$line/exe" >> "$destFile"
			# clean up
			rm -r "/tmp/$line"
		done
		# clean up
		rm "/tmp/pids.txt"
	fi
	space
	### collect all open files
	#echo "===== lsof" >> "$destFile"
    #lsof >> "$destFile"
	#space
    ### find all executable files (lots of results, takes a long time)
    #destFile="$destDir/Executables.txt"
    #echo "===== Executable Files" >> "$destFile"
    #find / -type f -executable >> "$destFile"
    #space
	sect_head "EXECUTABLES IN TARGETED DIRS"
	find_exes "/tmp"
	find_exes "/dev"
	find_exes "/var"
	# read /tmp/ex.txt and hash and stat
	cat "/tmp/ex.txt" | while read line
	do
		sha256="$(shasum -a 256 "$line" | awk '{print $1}')"
		md5sum="$(md5sum "$line" | awk '{print $1}')"
		echo "Executable: $line  -->  SHA256: $sha256 MD5: $md5sum" >> "$destFile"
		stat "$line" >> "$destFile"
	done
	rm "/tmp/ex.txt"
	space
}

function autoruns_ops {
	echo "Collecting basic autoruns information"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "BASIC AUTORUNS INFO"
    ### collect all systemd services
    echo "===== ls -lapR /etc/systemd/system"  | grep '.service' >> "$destFile"
    ls -lapR /etc/systemd/system  | grep '.service' >> "$destFile"
    space

    ### collect cron.d jobs
    echo "===== ls -lap /etc/cron.d" >> "$destFile"
    ls -lap /etc/cron.d >> "$destFile"
    echo >> "$destFile"

    ls -1 /etc/cron.d >> /tmp/crond.txt
    cat /tmp/crond.txt | while read line
    do
	    echo >> "$destFile"
		echo "--- $line" >> "$destFile"
	    cat "/etc/cron.d/$line" >> "$destFile"
    done
    rm /tmp/crond.txt
    space
}

function survey_dirs {
	echo "Collecting the contents of certain directories"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "DIRECTORY INFO"
	### contents of certain dirs
    	# ls -lapsSFT #s_ize, S_ort by size, F classify by filetype (exe, etc.), display time info
    	# /tmp
    	echo "===== ls -lapsSFt /tmp" >> "$destFile"
    	ls -lapsSFt /tmp >> "$destFile"
    	echo >> "$destFile"
    	# /var/tmp
    	echo "===== ls -lapsSFt /var/tmp" >> "$destFile"
    	ls -lapsSFt /var/tmp >> "$destFile"
    	echo >> "$destFile"
    	# /dev
    	echo "===== ls -lapsSFt /dev" >> "$destFile"
    	ls -lapsSFt /dev >> "$destFile"
    	echo >> "$destFile"
    	# /var/spool/cron
    	echo "===== ls -lapsSFt /var/spool/cron" >> "$destFile"
    	ls -lapsSFt /var/spool/cron >> "$destFile"
    	echo >> "$destFile"
    	# /etc/cron.d
   	 echo "===== ls -lapsSFt /etc/cron.d" >> "$destFile"
    	ls -lapsSFt /etc/cron.d >> "$destFile"
	space
}

function user_ops {
	echo "Collecting information about users of the system"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "USER INFO"
	echo "Currently Logged in Users" >> "$destFile"
	who >> "$destFile"
	echo >> "$destFile"
	### hash the /sbin/nologin file
	if [ -e "/sbin/nologin" ] ; then
		sha256NoLogin="$(shasum -a 256 "/sbin/nologin" | awk '{print $1}')"
		md5NoLogin="$(md5sum "/sbin/nologin" | awk '{print $1}')"
		echo "===== Hashes of /sbin/nologin  -->  SHA 256: $sha256NoLogin MD5: $md5NoLogin" >> "$destFile"
	else
		echo "===== /sbin/nologin does not exist!"
	fi
	
    ### read /etc/password
    echo "===== cat /etc/passwd (users that can log in) -----" >> "$destFile"
    cat /etc/passwd | grep -v '/bin/false' | grep -v '/sbin/nologin' | grep -v '/sbin/halt' | grep -v '/sbin/shutdown' >> "$destFile"
    echo >> "$destFile"

    echo "===== cat /etc/passwd" >> "$destFile"
    cat /etc/passwd >> "$destFile"
    echo >> "$destFile"

    ### read /etc/shadow and look for users that can log in
    echo "===== cat /etc/shadow" >> "$destFile"
    cat /etc/shadow >> "$destFile"
    space
	
    ### collect utmpdumps of *tmp logs
    destFile="$destDir/LoginLogs.txt"
    # current logins
    echo "===== utmpdump utmp (Current Logins)" >> "$destFile"
    utmpdump /var/run/utmp >> "$destFile" 2>> /dev/null
    echo >> "$destFile"
    # all valid past logins
    echo "===== utmpdump wtmp (All successful past logins)" >> "$destFile"
    
    if [ -e "/var/log/wtmp" ] ; then
        utmpdump /var/log/wtmp >> "$destFile" 2>> /dev/null
        echo >> "$destFile"
    fi
    
    # all bad logins
    echo "===== utmpdump btmp (All bad logins)" >> "$destFile"
    if [ -e "/var/log/btmp" ] ; then
        utmpdump /var/log/btmp >> "$destFile" 2>> /dev/null
        echo >> "$destFile"
    fi
    space
}

function ssh_info {
	echo "Collecting possible evidence of lateral movement"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "LATERAL MOVEMENT INFO"
	# find the IPs of systems that the system has attempted to ssh to
	echo "===== hosts the system has ssh'ed to" >> "$destFile"
	find / -name 'known_hosts' >> "/tmp/sshHosts.txt"
	
	if [ -e "/tmp/sshHosts.txt" ] ; then
		cat "/tmp/sshHosts.txt" | while read line
		do
			cat "$line" | awk '{print $1}' >> "$destFile"
		done	
		rm "/tmp/sshHosts.txt"
	else
		"No hosts detected"
	fi
	space
}

function log_ops {
	echo "Collecting logs"
	destFile="$destDir/sysInfoResults.txt"
	sect_head "SYSTEM LOG INFO"
    	### survey the /var/log directory
    	# sort by smallest to largest log file
    	echo "===== ls -lap /var/log" >> "$destFile"
    	ls -lap /var/log | sort -n -k 5,5 >> "$destFile"
    	echo >> "$destFile"

    	if [ -e "$destDir/var-log" ] ; then
        	rm -r "$destDir/var-log"
		mkdir "$destDir/var-log"
        	cp -r /var/log/* "$destDir/var-log"
    	else
        mkdir "$destDir/var-log"
        cp -r /var/log/* "$destDir/var-log"
    fi
}

### bash histories
function collect_bash_history {
	echo "Collecting bash_history"
	histFile="Bash_History.txt"
	find / -name '.bash_history' >> /tmp/historyFiles.txt

	cat /tmp/historyFiles.txt | while read line
	do
		length="${#line}"
		cutString="$((($length - 15)))"
		userName="${line:1:$cutString}"

		if [ "$userName" == "root" ] ; then
			cat "$line" >> "$destDir/$userName-$histFile"
		else
			# flush out additional users' bash_history
			afterHome=${userName#*home}
			lengthAfterHome="(( ${#afterHome} - 1 ))"
			afterCut="${afterHome:1:$lengthAfterHome}"
			cat "$line" >> "$destDir/$afterCut-$histFile"
		fi
	done
	rm /tmp/historyFiles.txt
}

function chown_files {
	chown -R "$userName" "$destDir"
}

##### collect info!
if [ -z "$param1" ] ; then
	check_root
	mk_collection_dir
	out_file_header
	mounted_fs
	process_ops
	network_ops
	file_ops
	user_ops
	autoruns_ops
	survey_dirs
	ssh_info
	log_ops
	collect_bash_history
	chown_files
else
	check_root
	mk_collection_dir
	out_file_header
	request_file_info "$param1"
	mounted_fs
	process_ops
	network_ops
	file_ops
	user_ops
	autoruns_ops
	survey_dirs
	ssh_info
	log_ops
	collect_bash_history
	chown_files
fi
