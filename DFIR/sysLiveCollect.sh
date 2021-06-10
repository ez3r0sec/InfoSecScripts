#!/bin/bash
# sysLiveCollect.sh
# collect volatile forensics data from a Linux/UNIX host (non-macOS)
# Last Edited: 6/27/18 Julian Thies

### VARIABLES
dest="$(pwd)/evidence/$(date +20%y-%m-%d)-$(hostname)-evidence.txt"

### FUNCTIONS
function space {
    echo >> "$dest"
}

### SCRIPT
# make a directory to host the evidence collection files
if [ -e "$(pwd)/evidence" ] ; then
    rm -r "$(pwd)/evidence"
    mkdir "$(pwd)/evidence"
else
    mkdir "$(pwd)/evidence"
fi

## write the evidence file
# write the date to the top of the evidence text file
date >> "$dest"
space

# hash the script
echo "========== SCRIPT HASHES <shasum -a 256  \  md5sum>" >> "$dest"
echo "SHA256: $(shasum -a 256 "$0")" >> "$dest"
echo "MD5   : $(md5sum "$0")" >> "$dest"
space

# system info
echo "========== SYSTEM INFO <hostname  \  uname -o  \  uname -m  \  cat /etc/*release | grep 'PRETTY_NAME'>" >> "$dest"
echo "Hostname : $(hostname)" >> "$dest"
echo "Operating system : $(uname -o)" >> "$dest"
echo "Operating System Architecture : $(uname -m)" >> "$dest"
echo "Distribution : $(cat /etc/*release | grep 'PRETTY_NAME')" >> "$dest"
space

# timezone information
echo "========== TIMEZONE INFO <timedatectl>" >> "$dest"
timedatectl >> "$dest"
space

# currently logged in users
echo "========== LOGGED IN <who>" >> "$dest"
who >> "$dest"
space

# memory
echo "========== MEMORY USAGE in MB <free -m>" >> "$dest"
free -m >> "$dest"
space

# mounted drives
echo "========== MOUNTED DRIVES <df -aTH>" >> "$dest"
df -aTH >> "$dest"
space

# network state
echo "========== NETWORK INFO <ifconfig  \  netstat -apee --numeric-ports>" >> "$dest"
ifconfig >> "$dest"
space
netstat -apee --numeric-ports >> "$dest"
space

# process information
echo "========== PROCESSES <ps auxwfZ | sort -n -k 3,3>" >> "$dest"
ps auxwfZ | sort -n -k 3,3 >> "$dest"
space
ls -la /proc | grep 'deleted' >> "$dest"
space

### LOGS
echo "========== LOG DIR <ls -lapSFtR>" >> "$dest"
# look at the /var/log directory
ls -lapSFtR /var/log >> "$dest"
space

# all open files
echo "========== OPEN FILES <lsof +E -KPR>" >> "$dest"
lsof +E -KPR >> "$dest"
space

# hash the script
echo "========== SCRIPT HASHES <shasum -a 256  \  md5sum>" >> "$dest"
echo "SHA256: $(shasum -a 256 "$0")" >> "$dest"
echo "MD5   : $(md5sum "$0")" >> "$dest"
space

# end the script with the current time
date >> "$dest"