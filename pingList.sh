#!/bin/bash
# pingList.sh
# ping a list of IPs passed in as a text file (paramenter 1)
#+with the format below

# file format
#10.0.0.1
#10.0.0.2
#10.0.0.240
#10.0.0.5
#10.0.4.8

if [ "$1" == "" ] ; then
	echo "Pass in the IP file path as param 1"
	exit
else
	echo "---- Commencing ping test ----"
fi

cat $1 | while read line
do
	pingHost="$(ping -c 2 $line | grep 'icmp_seq=1 Destination Host Unreachable')"
	if [ "$pingHost" != "" ] ; then
		echo "*** $line --> UNREACHABLE ***"
	else
		echo "$line is up"
	fi
done
echo "---- Ping test complete ----"
exit
