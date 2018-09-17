#!/usr/bin/python
# collectBashHist.py
# collect all bash_history on a system for analysis (Python 2.7)
# Last Edited: 7/23/18

### IMPORT
import os
import shutil

### VARIABLES
destDir = os.path.join("/usr/local/", str(os.uname()[1] + "_bh")

### FUNCTIONS
def mk_dir(dir):
	if not os.path.exists(dir):
		os.mkdir(dir)
	else:
		pass
                
def find_hist(path, dest):
	if os.path.exists(path):
		for path, dir, files in os.walk(path):
			for file in files:
				if file.endswith('bash_history'):
					fp = os.path.join(path, file)
					fpString = list(fp)
					# take filepath and replace "/" with "_" to name the destination file
					for i in range(len(fpString)):
						if fpString[i] == "/":
							fpString[i] = "_"
					name = "".join(fpString)
					destFile = os.path.join(dest, name)
					shutil.copy(fp, destFile)
				else:
					pass
	else:
		pass
                                                                                
### SCRIPT
mk_dir(destDir)
find_hist("/", destDir)
