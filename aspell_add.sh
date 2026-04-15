#!/bin/bash

set -e

ROOT_UID=0
NOTROOT=87

# Check if user is root
if [ "$EUID" -ne "$ROOT_UID" ]; then
    echo "You must be root to run this script."
    exit "$NOTROOT"
fi

wget https://ftp.gnu.org/gnu/aspell/dict/bg/aspell6-bg-4.1-0.tar.bz2
tar -xf aspell6-bg-4.1-0.tar.bz2
cd aspell6-bg-4.1-0 || exit 1

apt install -y make aspell

./configure
make
make install

if aspell -l bg dump master | grep -q "здравей"; then
    echo "aspell инсталиран - ОК"
else
    echo "aspell не е инсталиран или речникът не работи"
fi