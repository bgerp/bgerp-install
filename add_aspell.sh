#!/bin/bash

set -e

ROOT_UID=0
NOTROOT=87

# Check if user is root
if [ "$EUID" -ne "$ROOT_UID" ]; then
    echo "You must be root to run this script."
    exit "$NOTROOT"
fi

display_help() {
    echo "Usage: $0 [option= ...]" >&2
    echo
    echo "   -h, --help                 Show this help"
    echo
    exit 1
}

wget https://ftp.gnu.org/gnu/aspell/dict/bg/aspell6-bg-4.1-0.tar.bz2
tar -xf aspell6-bg-4.1-0.tar.bz2
cd aspell6-bg-4.1-0 || exit 1

apt install -y make aspell

./configure
make
make install

aspell -l bg dump master | grep здравей