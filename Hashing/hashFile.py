#!/usr/bin/python
# hashFile.py
# pass in the target file as param 1
# Last Edited: 5/11/18 Julian Thies

### IMPORTS
import os.path
import hashlib
import sys

### FUNCTIONS
def hash_file(filename):
     if os.path.exists(filename):
          bufferSize = 65536
          md5Hash = hashlib.md5()
          sha1Hash = hashlib.sha1()
          sha256Hash = hashlib.sha256()
          with open(filename, 'rb') as f:
               while True:
                    data = f.read(bufferSize)
                    if not data:
                         break
                    md5Hash.update(data)
                    sha1Hash.update(data)
                    sha256Hash.update(data)

          print
	  print("md5:    {0}".format(md5Hash.hexdigest()))        # calculate and display the hashes
          print("sha1:   {0}".format(sha1Hash.hexdigest()))
          print("sha256: {0}".format(sha256Hash.hexdigest()))

     else:
          print(filename + " does not exist")

### SCRIPT
arg = sys.argv[1]
hash_file(arg)
