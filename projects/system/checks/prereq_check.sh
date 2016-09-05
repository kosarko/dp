#!/bin/bash

SCRIPTDIR=$(dirname $(readlink -e $0)) 
LOCPATH=$SCRIPTDIR/../local_paths
echo "sourcing local_paths:"
cat $LOCPATH
. $LOCPATH

function check {
 echo "Checking $1:"
 if ! which $1; then
     echo "$1 not found"
     echo $PATH
     echo -e "Install it with: $2"
 fi
}

function check_set_exists {
 echo "Checking $1 is set and exists:"
 if [ -z "$1" -o ! -d "$1" ]; then
     echo "$1 is not set or not a directory"
     echo -e "$2"
 fi
}

check soxi
check perl
check python3
check sqlite3 'wget -O ~/Downloads/sqlite3.zip "http://www.sqlite.org/2016/sqlite-tools-linux-x86-3130000.zip"\nunzip ~/Downloads/sqlite3.zip -d /tmp/workdir/sqlite3\nand add it to path'
check_set_exists $KALDI_DIR 'Set KALDI_DIR in local_paths'
check ngram-count 'Install srilm'
