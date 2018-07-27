#!/bin/bash
# ransomwareThreatInfo.sh
# ransomware indicators from ransomwaretracker.abuse.ch
# Last Edited: 6/14/18 Julian Thies

### VARIABLES
starDate="$(date +%y_%m_%d)"
destFile1="/tmp/$starDate-ransomware"
destFile2="/home/$(id -un)/Desktop/$starDate-ransomware"

baseURL="https://ransomwaretracker.abuse.ch/downloads"

overallDomList="RW_DOMBL.txt"
overallIPList="RW_IPBL.txt"
overallURLList="RW_URLBL.txt"

### FUNCTIONS
function dl_list (){
    listURL="$baseURL/$1"
    # figure out what kind of IOC it is (DOM, IP, or URL)
    lenString="${#1}"
    cutString="$((($lenString - 9)))"
    typeString="${1:3:$cutString}"
    # dl the file
    curl -s -o "$destFile1-$typeString.txt" "$listURL"
    # process the files
    grep -v "\#" "$destFile1-$typeString.txt" >> "$destFile2-$typeString.txt"
}

### SCRIPT
dl_list "$overallDomList"
dl_list "$overallIPList"
dl_list "$overallURLList"

rm /tmp/$starDate-ransomware*
