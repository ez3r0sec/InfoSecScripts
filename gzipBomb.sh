#!/bin/bash
# -----------------------------------------------------------------------------
# gzipBomb.sh
# generate gzip bomb to frustrate attackers
# Last Edited: 8/8/17
# -----------------------------------------------------------------------------
# check if user has passed in a string to the $1 parameter for the file name
if [ "$1" != "" ] ; then
    fileName=$1
    # check if user has passed in a string to the $2 parameter for the size
    if [ "$2" != "" ] ; then
	sizeCount=$2
	cd /tmp
	echo "generating $fileName.gzip"
	dd if=/dev/zero bs=1M count=$sizeCount | gzip > $fileName.gzip
	mv $fileName.gzip ~/Desktop
    else
	echo "Pass in a size for the .gzip bomb in the second position (102420 ~ 10 GB)"
    fi
else
    echo "Pass in a file name for the .gzip bomb in the first position" 
    echo "Pass in a size for the .gzip bomb in the second position (102420 ~ 10 GB)"
fi
exit
# -----------------------------------------------------------------------------
