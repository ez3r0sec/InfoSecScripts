#!/bin/bash
# install clamscan job for ubuntu/debian fileshares
# Last Edited: 12/17/17 Julian Thies

# check if ClamAV is already installed
if [ -e /usr/bin/clamscan ] ; then
    echo "Clamav is installed! Continuing the installation"
    echo "Updating the virus database"
    sudo freshclam
else
    echo "Installing ClamAV"
    sudo apt-get install clamav -y
    if [ -e /usr/bin/clamscan ] ; then
        echo "Clamav is installed! Continuing the installation"
        echo "Updating the virus database"
        sudo freshclam
    else
        echo "ClamAV is not installed. Try again."
        exit
    fi
fi

# variables
jobName="/tmp/ClamScanJob"
scriptName="/tmp/clamScanJob.sh"
scanString="sudo /usr/bin/clamscan -r $targetDir | grep -v 'OK' | grep -v 'Empty file' 1>> $logFile "

# build job script in /tmp
echo "Writing script to /tmp"

echo "#!/bin/bash" >> "$scriptName"
echo "starDate="$(date +%y-%m-%d)" >> "$scriptName"
echo "targetDir="/srv/" >> "$scriptName"
echo "logFile=/tmp/$starDate-Clamscan.log" >> "$scriptName"
echo >> "$scriptName"
echo "# Generated by a bash script" >> "$scriptName"
echo >> "$scriptName"
echo "sudo freshclam" >> "$scriptName"
echo "$scanString" >> "$scriptName"
echo >> "$scriptName"

# build cron job in /tmp
echo "Writing cron.d job"

sudo echo "*/05 * * * * root bash /usr/local/clamScanJob.sh" >> "$jobName"

# give permission to script and copy over to /usr/local
echo "Copying the script to /usr/local"

sudo chmod +x "$scriptName"
sudo cp "$scriptName" /usr/local

# copy the scan job file to cron.d
echo "Copying cron.d job to /etc/cron.d"

sudo cp "$jobName" /etc/cron.d

echo "Process complete"

exit
