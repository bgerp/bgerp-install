#!/bin/bash
set -e
echo "Cleaning Temp dir ..."
shopt -s extglob
cd /tmp
rm -rfv !("start.sh")
#
apt-get -y autoremove && \
apt-get clean && \
apt-get autoclean && \
rm -rf /var/lib/apt/lists/*