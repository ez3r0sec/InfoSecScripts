#!/usr/bin/python
# injectTimeStampBashHist.py
# inject timestamps into bash history
# Last Edited: 4/19/18 Julian Thies

''' imports '''
import os
import glob
import platform
import time
from time import strftime

''' variables '''
runTime = strftime("%Y-%m-%d-%H-%M-%S", time.localtime())
systemType = platform.system()
userList = ''

timeLine = '[ ==================== ' + runTime + ' ==================== ]'

''' functions '''
def check_system_type():
	# there are much more elegant ways to do this, but this will probably suffice
	global userList
	if systemType == 'Linux':
		userList = glob.glob('/home/*')
	elif systemType == 'FreeBSD':
		userList = glob.glob('/usr/home/*')
	elif systemType == 'Darwin':
		# macOS
		print('File a request to add support for adding a launch daemon for macOS')
		userList = glob.glob('/Users/*')
	else:
		print('Could not determine OS, exiting')
		exit 1

def write_line(filename, contents):
	with open(filename, 'a') as f:
		f.write(contents + os.linesep)

def inject_time_users(contents):
	for i in range(len(userList)):
		if userList[i] != '/home/lost+found':
			bashHistory = userList[i] + "/" + ".bash_history"
			if os.path.exists(bashHistory):
				write_line(bashHistory, contents)

def inject_time_root(contents):
	bashHistory = "/.bash_history"
	if os.path.exists(bashHistory):
		write_line(bashHistory, contents)
	bashHistory = "/root/.bash_history"
	if os.path.exists(bashHistory):
		write_line(bashHistory, contents)

''' script '''
check_system_type()
inject_time_users(timeLine)
inject_time_root(timeLine)
