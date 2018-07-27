#!/bin/bash
# beginExam.sh
# script to automate some basic tasks to begin a malware examination
# Last Edited: 7/19/18 Julian Thies

### VARIABLES
starDate="$(date +%y-%m-%d)"
userName="$(id -un)"
# main output files
logFile="/home/$userName/Desktop/$starDate-Forensics-Log.txt"
outputFile="/home/$userName/Desktop/$starDate-Forensics-Results.txt"
# strings files
stringsDir="/home/$userName/Desktop/$starDate-Strings"
rawStrings="$stringsDir/ALL-Strings.txt"
interestStringsFile="$(pwd)/Strings-Of-Interest.txt"
stringsOfInterest="$stringsDir/stringsOfInterest.txt"

### SCRIPT
# make sure something is passed in to analyze
if [ -z "$1" ] ; then
	echo "No file passed in"
	exit
fi

##############################################
##### ----- prompt for options
printf "Turn off network interface? (y/n) -> "
read A
if [ "$A" == "y" ] ; then
	echo "Turning off internet connection"
	sudo ifconfig enp0s3 down
	sleep 10
elif [ "$A" == "n" ] ; then
	echo "Network interface will remain active"
else
	echo "Invalid input"
	exit
fi

echo

# initialize the output file
echo "$starDate Forensic Report" >> $outputFile
echo >> $outputFile
echo "Filename: $1" >> $outputFile
echo >> $outputFile

##### ----- Hashes
echo "---- Hashes ----" >> $outputFile

echo "MD5 hash:" >> $outputFile
md5sum "$1" >> $outputFile
echo >> $outputFile

echo "SHA1 hash:" >> $outputFile
sha1sum "$1" >> $outputFile
echo >> $outputFile

echo "SHA256 hash:" >> $outputFile
sha256sum "$1" >> $outputFile
echo >> $outputFile

#####
echo >> $outputFile
echo "---------" >> $outputFile

################################
##### ----- Strings
mkdir "$stringsDir"

# raw strings
strings "$1" >> "$rawStrings"

# use developed list to filter from raw strings
cat "$interestStringsFile" | while read line
do
    #patternToSearch="$line"
    grep -n "$line" "$rawStrings" >> "$stringsOfInterest"
done
