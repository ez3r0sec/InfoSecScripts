#!/bin/bash
# ----------------------------------------------------------------------------
# collectObjSeeHashes.sh
# collect Mac malware SHA 256 hashes from Objective-See's collection
# Last Edited: 2/28/18 Julian Thies
# ----------------------------------------------------------------------------
# some variables
jsonURL="https://objective-see.com/malware.json"
userName="$(id -un)"

macResultsDir="/Users/$userName/Desktop"
linuxResultsDir="/home/$userName/Desktop"

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
                # echo Mac malware hashes to a text file on the Desktop
                if [ -d /Users ] ; then
        		echo "$sha256Hash" >> $macResultsDir/sha256Hashes.txt
		else
			echo "$sha256Hash" >> $linuxResultsDir/sha256Hashes.txt
		fi     
	else
                # echo lines that did not work for some reason to a file as well
		if [ -d /Users ] ; then                
			echo "$sha256Hash" >> $macResultsDir/scriptErrors.txt
		else
			echo "$sha256Hash" >> $linuxResultsDir/scriptErrors.txt
       		fi
	fi
done

# clean up
rm /tmp/malware.json
rm /tmp/links.txt
# ----------------------------------------------------------------------------
