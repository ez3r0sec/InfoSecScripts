#!/usr/bin/python
# checkIfExecutable.py
# check the permission bits to determine if a file is executable
# Last Edited: 10/3/18 Julian Thies

### IMPORTS
import os
import sys

### VARIABLES
arg = sys.argv[1]

### FUNCTIONS
def checkExecutable(file):
	# check if the file actually exists
	if os.path.exists(file):
		# permission values required for a file to be executable
		possible_permissions = [1, 3, 5, 7]
		# get the octal value of permissions and chop off the first two digits
		permissions = oct(os.stat(file)[0])[-3:]
		# separate the digits
		perm_split = list(permissions)
		count = 0
		for i in range(len(perm_split)):
			if int(perm_split[i]) in possible_permissions:
				count = count + 1
				# exit right away if the file is deemed executable
				exit()
			else:
				pass
	
		if count > 0:
			print(True)
		else:
			print(False)
	else:
		print(file + " does not exist!")

### SCRIPT
checkExecutable(arg)

