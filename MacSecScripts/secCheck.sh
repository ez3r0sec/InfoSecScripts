#!/bin/bash
# -----------------------------------------------------------------------------
# secCheck.sh
# check for macOS security settings and patches
# Last Edited: 6/15/18 Julian Thies
# -----------------------------------------------------------------------------
### VARIABLES
userName="$(whoami)"

### FUNCTIONS
function check_sudo {
	if [ "$userName" != "root" ] ; then
		echo "$0 must be run using sudo"
		exit
	fi
}

function intro_message {
	clear
    	echo "[ ==================================================== ]"
    	echo "[ =========== security checkup for macOS ============= ]"
    	echo "[ ==================================================== ]"
	echo 
	echo "Beginning security checkup..."
}

function sys_vers {
	echo "System version is:"
	sw_vers
}

# function to check the installed version of flash against the current version
function flash_vers {
	# check local version
	flashVersion="$(defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version.plist | awk '/CFBundleVersion/ {print $(3) }')"
	lenString="${#flashVersion}"
	cutString="$((($lenString - 3)))"
	localVersion="${flashVersion:1:$cutString}"

	# curl html file
	curl -sL http://www.adobe.com/software/flash/about/ > /tmp/AdobeFlashVersion.html

	# reads html file and pulls out lines that include $localVersion
	cat /tmp/AdobeFlashVersion.html | while read line
	do
    		awk '/'"$localVersion"'/ {print $(NF) }' >> /tmp/htmlVersion.txt
	done

	# read htmlVersion and cuts the strings down, then compares them to $localVersion
	cat /tmp/htmlVersion.txt | while read line
	do
    		lenString="${#line}"
    		cutString="$((($lenString - 9)))"
    		webVersion="${line:4:$cutString}"
    		if [ "$webVersion" == "$localVersion" ] ; then
        		echo "$webVersion" > /tmp/Latest.txt
    		else
        		vers="Old"
    		fi
	done

	# checks if the file /tmp/Newest.txt exists
	if [ -f "/tmp/Latest.txt" ] ; then
    		echo "Flash player is up to date"
	else
    		echo "Flash player is outdated"
    		echo "The current version is $webVersion"
    		echo "The installed version is $localVersion"
	fi
	rm /tmp/Latest.txt
	rm /tmp/htmlVersion.txt
	rm /tmp/AdobeFlashVersion.html
}

# check if flash is installed
function chk_flashPlayer {
	if [ -f "/Library/Internet Plug-Ins/Flash Player.plugin/Contents/version.plist" ] ; then
		echo "Flash is installed on this system, checking the version against the current version"
		flash_vers
	else
		echo "Flash is not installed on this system!"
	fi
}

function java_vers {
	javaVersion="$(defaults read /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist | awk '/CFBundleVersion/ {print $(3) }')"
	lenString="${#javaVersion}"
	cutString="$((($lenString - 3)))"
	localVersion="${javaVersion:1:$cutString}"
	
	curl -sL https://java.com/en/download/ >> /tmp/javahtmlVers.html
	# reads html file and pulls out lines that include $localVersion
	
	webVersion="$(grep 'Update' /tmp/javahtmlVers.html)"
  	echo "The current version is $webVersion"
    	echo "The installed version is $localVersion"

	rm /tmp/javahtmlVers.html
}

function chk_java {
	if [ -f "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist" ] ; then
		echo "Java is installed on this system, checking the version against the current version"
		java_vers
	else
		echo "Java Runtime Environment is not installed on this system!"
	fi
}

function software_updates {
	echo "Checking for software updates from Apple"
	softwareupdate -l
}

function check_efi_password {
	checkPass="$(/usr/sbin/firmwarepasswd -check | awk '/Password/ {print $(3) }')"
	if [ "$checkPass" == "Yes" ] ; then
    		echo "EFI password enabled!</result>"
	else
    		echo "*** NO EFI password set!"
	fi
}

function check_update_settings {
	autoCheckEnabled="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | awk '/AutomaticCheckEnabled = / {print $(3) }')"
	if [ "$autoCheckEnabled" != "1;" ] ; then
		echo "*** Automatic checking for updates is not on"
	fi
	# parameter for automatic app updates
	commerceAutoUpdate="$(defaults read /Library/Preferences/com.apple.commerce | awk '/AutoUpdate = / {print $(3) }')"
	if [ "$commerceAutoUpdate" != "1;" ] ; then
		echo "*** Automatic app updates disabled"
	fi
	# parameter for macOS updates
	autoMacUpdate="$(defaults read /Library/Preferences/com.apple.commerce | awk '/AutoUpdateRestartRequired = / {print $(3) }')"
	if [ "$autoMacUpdate" != "1;" ] ; then
		echo "*** Automatic macOS updates disabled"
	fi
	# parameter for automatic download of available updates
	autoMacDownload="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | awk '/AutomaticDownload = / {print $(3) }')"
	if [ "$autoMacDownload" != "1;" ] ; then
		echo "*** Automatic download of available updates disabled"
	fi
	# first parameter as part of "install system files" option
	sysDataFiles1="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | awk '/CriticalUpdateInstall = / {print $(3) }')"
	if [ "$sysDataFiles1" != "1;" ] ; then
		echo "*** Automatic installation of critical updates disabled! (1/2)"
	fi
	# second parameter as part of "install system files" option
	sysDataFiles2="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate | awk '/ConfigDataInstall = / {print $(3) }')"
	if [ "$sysDataFiles2" != "1;" ] ; then
		echo "*** Automatic installation of critical updates disabled! (2/2)"
	fi
}
function check_remote_access {
	sshCheck="$(systemsetup getremotelogin | awk '/Remote/ {print $(3) }')"
	if [ "$sshCheck" == "On" ] ; then
		echo "*** SSH server is on!"
	fi
	lineTemplate="com.apple.RemoteDesktop.agent"
	ARD="$(launchctl list | grep '^\d.*RemoteDesktop.*')"
	Agent="$(echo $ARD | awk '/com.apple.RemoteDesktop.agent/ {print $(NF) }')"
	if [ "$Agent" == "$lineTemplate" ] ; then
		echo "*** Apple Remote Desktop may be on!"
	fi
	if [ -f /etc/com.apple.screensharing.agent.launchd ] ; then
		echo "*** Screen sharing may be on!"
	fi
}

function check_logged_in {
	echo "SSH/Telnet Users logged in:"
	who
	echo "Users that have logged in:"
	last
}

function check_guest {
	guestEnabled="$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled)"
	if [ "$guestEnabled" == "1" ] ; then
		echo "*** The Guest account is enabled!"
	else
		echo "The Guest account is disabled"
	fi
}

function check_file_sharing {
	if [ "$(launchctl list | grep AppleFileServer)" != "" ] ; then
		echo "*** File sharing over AFP is ON"
	fi
	if [ "$(launchctl list | grep smbd)" != "" ] ; then
		echo "*** File sharing over SMB is ON"
	fi
	
	if [ "$(launchctl list | grep AppleFileServer)" == "" ] && [ "$(sudo launchctl list | grep smbd)" == "" ] ; then
		echo "File sharing is off"
	fi
}

function check_gatekeeper {
	gkeeperOn="$(spctl --status | grep 'enabled')"
	if [ "$gkeeperOn" == "assessments enabled" ] ; then
		echo "Gatekeeper is on"
	else
		echo "*** Gatekeeper is off!"
	fi
}

function check_SIP {
	sipEnabled="$(csrutil status | grep 'enabled')"
	if [ "$sipEnabled" == "System Integrity Protection status: enabled." ] ; then
		echo "System Integrity Protection is enabled"
	else
		echo "*** System Integrity Protection is disabled!"
	fi
}

function check_ALF {
	globalState="$(defaults read /Library/Preferences/com.apple.alf.plist globalstate)"
	if [ "$globalState" == "1" ] ; then
		echo "Application Layer Firewall is enabled"
	else
		echo "*** Application Layer Firewall is disabled!"
	fi
}

function check_stealth {
	stealthStatus="$(defaults read /Library/Preferences/com.apple.alf.plist stealthenabled)"
	if [ "$stealthStatus" == "0" ] ; then
		echo "*** Application Layer Firewall stealth mode Disabled!"
	else
		echo "Application Layer Firewall stealth mode enabled"
	fi
}

function check_hostname {
	hostname > /tmp/HostName.txt
	baseModel="$(system_profiler -detaillevel mini | grep 'Model Name' | awk '/Model Name/ {print $3}')"
	if [ "$(grep '$baseModel' /tmp/HostName.txt)" != "" ] ; then
		echo "*** Hostname is default!"
	else
		echo "Hostname is not default"
	fi
	rm /tmp/HostName.txt
}
# -----------------------------------------------------------------------------
check_sudo
intro_message
sys_vers
chk_flashPlayer
chk_java
software_updates
check_update_settings
check_efi_password
check_remote_access
check_logged_in
check_guest
check_file_sharing
check_gatekeeper
check_SIP
check_ALF
check_stealth
check_hostname
exit
# -----------------------------------------------------------------------------
