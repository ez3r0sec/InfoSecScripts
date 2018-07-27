#!/bin/bash
# ----------------------------------------------------------------------------
# macBashAV.sh
# collect malware hashes from Objective-See and compare to local files as a 
#+crude AV implementation
# Last Edited: 4/25/18 Julian Thies
# ----------------------------------------------------------------------------
# set the stage for scanning
scanDir="$1"

if [ "$scanDir" == "" ] ; then
	echo "Usage: $0 <directory>"
	exit
fi

# some variables
jsonURL="https://objective-see.com/malware.json"
results="/tmp/hashes.txt"

dirContents="/tmp/dirContents.txt"
hashStore="/tmp/sysHashes.txt"

infectedFile="/tmp/infected.txt"

###
### [=== collect hashes from Objective-See ===] ###
###
function download_IOCs {
	# grab the json file from Objective-See
	curl -s -o /tmp/malware.json "$jsonURL"

	# Pull out lines containing the VT URLs and then isolate the URL
	cat /tmp/malware.json | grep 'virusTotal' | awk '/virusTotal/ {print $2}' >> /tmp/links.txt

	# Read each URL and cut it down to just the SHA 256 hash
	cat /tmp/links.txt | while read line
	do
		lenString="${#line}"
		cutString="$((($lenString - 38)))"
		sha256Hash="${line:35:$cutString}"
		# if hash string is not exactly 64 characters, send it to an errors file
		lenHashString="${#sha256Hash}"
		if [ "$lenHashString" == 64 ] ; then
			# echo Mac malware hashes to a text file
		  	echo "$sha256Hash" >> "$results" 
		else
		    # echo lines that did not work for some reason to a file as well
			echo "$sha256Hash" >> /tmp/errors.txt
		fi
	done
	# can test if it is working by uncommenting the next line and adding an empty file to the
  	#+scanDir
  	#echo "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" >> "$results"

	# clean up
	rm /tmp/malware.json
	rm /tmp/links.txt
}

###
### [============ compare to files ============] ###
###
function iterate_hashes () {
	if [ -z "$1" ] ; then
		echo "<result>A hash was not passed in to the iterate_hashes function</result>"
		exit 1
	else
		cat "$results" | while read line
		do
			if [ "$1" == "$line" ] ; then
				fileName="$(grep "$1" "$hashStore")"
				echo "$fileName  :  INFECTED" >> "$infectedFile"
			fi
		done
	fi
}

function hash_file () {
	if [ -z "$1" ] ; then
		echo "A hash was not passed in to the hash_file function"
		exit 1    
	else
		if [ -d "$line" ] ; then
		    echo "$line is a directory"
		else
		    sha256="$(shasum -a 256 "$line" | awk '$1 {print $1}')"
			if [ "$sha256" != "" ] ; then
				#echo "$line  :  $sha256"
				echo "$line  :  $sha256" >> "$hashStore"
				iterate_hashes $sha256
			fi
		fi
	fi
}

function traverse_dirs {
	find "$scanDir" -type f >> "$dirContents" #"*$scanDir/*"
	cat "$dirContents" | while read line
	do
		hash_file "$line"
	done	

	rm "$dirContents"
}

# ----------------------------------------------------------------------------
download_IOCs
traverse_dirs

if [ -e "$infectedFile" ] ; then
	echo "$(cat $infectedFile)"
else
	echo "No files matching known malware on Objective-See.com"
fi

rm /tmp/*.txt
# ----------------------------------------------------------------------------
