#!/bin/bash
# disableGuestAccount.sh
# disable the macOS guest account
# Last Edited: 6/19/18 Julian Thies

if [ "$(whoami)" != "root" ] ; then
	echo "This script must be run as root or with sudo privileges"
	exit
else
	if [ -e "/Users/Guest" ] ; then
		# use dscl to delete the account
		dscl . -delete /Users/Guest
		# write to the login window plist to disable Guest
		defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO
		# write to the file server plists
		defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool NO
		defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool NO
	fi
fi
