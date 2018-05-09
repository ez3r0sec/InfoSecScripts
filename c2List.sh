#!/bin/bash
######################################
# c2List.sh
# get c2 list from Bambenek Consulting
# Last Edited: 2/28/18 Julian Thies
######################################
# variables
userName="$(id -un)"
starDate="$(date +%y-%m-%d)"

outDir="/home/$userName/Desktop/C2Search"
outFileDir="$outDir/$starDate"

outFileDom="RawDomains.txt"
outFileIP="RawIPs.txt"

listURLDom="http://osint.bambenekconsulting.com/feeds/c2-dommasterlist.txt"
listURLIP="http://osint.bambenekconsulting.com/feeds/c2-ipmasterlist.txt"
curlDomFile="/tmp/curlDoms.txt"
sedDomFile="/tmp/sedDoms.txt"
curlIPFile="/tmp/curlIPs.txt"
sedIPFile="/tmp/sedIPs.txt"
domFile="C2-Domains.txt"
IPFile="C2-IPs.txt"

######################################
# script
if [ -e "$outDir" ] ; then
    if [ -e "$outFileDir" ] ; then
	echo
    else
	echo "Creating $outFileDir"
	mkdir "$outFileDir"
    fi
else
    echo "Creating $outFDir"
    mkdir "$outDir"
    echo "Creating $outFileDir"
    mkdir "$outFileDir"
fi

# curl c2 List
curl -s -o "$outFileDir/$outFileDom" "$listURLDom"
curl -s -o "$outFileDir/$outFileIP" "$listURLIP"

# cut out just the IP addresses/Domains
##domains
curl $listURLDom | awk '{print $1}' > "$curlDomFile"
sed -e '1,16d' "$curlDomFile" > "$sedDomFile"
cat "$sedDomFile" | while read line
do	
    lenString="${#line}"
    cutString="$((($lenString - 7)))"
    localVersion="${line:0:$cutString}"
    echo "$localVersion" >> "$outFileDir/$domFile"
done

##IPs
curl $listURLIP | awk '{print $1}' > "$curlIPFile"
sed -e '1,16d' "$curlIPFile" > "$sedIPFile"
cat "$sedIPFile" | while read line
do	
    lenString="${#line}"
    cutString="$((($lenString - 3)))"
    localVersion="${line:0:$cutString}"
    echo "$localVersion" >> "$outFileDir/$IPFile"
done

exit
######################################
