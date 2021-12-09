#!/bin/bash
mkdir -p ./mount
mkdir -p ./db
chmod o+rw ./mount
chmod o+rw ./db
NOW=`date +%Y%m%d%H%M%S`
git clone -b master https://github.com/bgerp/bgerp.git
echo "Building bgerp:$NOW"
docker build -t "bgerp:$NOW" -t "bgerp:latest" .