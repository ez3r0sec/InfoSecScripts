#!/bin/bash
# hashFile.sh
# hash a file passed in as parameter 1
# Last Edited: 5/11/18 Julian Thies

hashFile="$1"

echo "md5    --> $(md5 $hashFile | awk '{print $4}')"
echo "sha1   --> $(shasum $hashFile | awk '{print $1}')"
echo "sha256 --> $(shasum -a 256 $hashFile | awk '{print $1}')"
