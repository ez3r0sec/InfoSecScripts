#!/bin/bash
# convertDMG.sh
# convert a dmg image to img and mount
# Last Edited: 6/21/18 Julian Thies

# ====================
# Requirements:
# dmg2img
# ====================

# check if we have the privs we need
if [ "$(whoami)" != "root" ] ; then
	echo "Script must be run as root or with sudo privileges"
	exit
fi

# check if dmg2img is installed
if [ "$(find / -name dmg2img)" == "" ] ; then
	echo "dmg2img is not installed!"		
	exit
fi

# check if anything was passed in to the script
if [ -z "$1" ] ; then
	echo "No DMG file passed in"
	exit
else
	echo "Converting $1 from DMG to IMG format"
	dmg2img "$1"
fi
