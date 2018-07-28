#!/bin/bash
# install.sh
# install injectTimeStampBashHist.py
# Last Edited: 4/19/18 Julian Thies

### variables
destDir="$1"
projName="injectTimeStampBashHist.py"

### functions
function run_install_root {
	chown root "$projName"
	chmod +x "$projName"
	cp "$projName" "$destDir"
	# prepare the cron.d install script
	chmod +x install_crond.py
	# run it!
	./install_crond.py "$destDir"
}

function run_install_sudo {
	sudo mkdir "$destDir"
	sudo chown root "$projName"
	chmod +x "$projName"
	sudo cp "$projName" "$destDir"
	# prepare the cron.d install script
	chmod +x install_crond.py
	# run it!
	./install_crond.py "$destDir"
}

function check_user {
	currentUser="$(whoami)"
	if [ "$currentUser" == "root" ] ; then
		echo "You are root! Be careful...Installing anyway"
		run_install_root
	else
		printf "Do you ( $currentUser ) have sudo rights? (y/n) -> "
		read A
		if [ "$A" == "n" ] ; then
			echo "Elevate to root or use a different user account"
			exit
		elif [ "$A" == "y" ] ; then
			run_install_sudo
		else
			echo "Invalid input, exiting..."
			exit
		fi
	fi
}

### script
if [ "$1" == "" ] ; then
	echo "usage: $0 <directory>"
	exit
else
	check_user
fi

echo "Done!"
exit
