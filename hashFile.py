#!/usr/bin/python
# hash a file using python
# pass in the file as param 1

import os.path
import hashlib
import sys

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

arg = sys.argv[1]
hash_file(arg)
