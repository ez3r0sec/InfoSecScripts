#!/bin/bash
# curlTop50.sh
# collect the Alexa top 50 websites
# Last Edited: 5/11/18 Julian Thies

userName="$(id -un)"
URL="https://www.alexa.com/topsites"
destFile="/home/$userName/Desktop/topSites.txt"

curl -s "$URL" | grep '<a href="/siteinfo/' | while read line
do
    # first round of processing	
	lenString="${#line}"
	cutString="$((($lenString - 23)))"
	newLine="${line:19:$cutString}"
    # second round of processing
	lenString="${#newLine}"
	cutString="$((($lenString - ( $lenString / 2 ) - 1 )))"
	newLine2="${newLine:0:$cutString}"
	echo "$newLine2" >> "$destFile"
done
