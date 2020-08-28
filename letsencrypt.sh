#!/bin/bash

ROOT_UID=0
NOTROOT=87

# Check if user is root
if [ $UID -ne $ROOT_UID ]
    then echo “You must be root to run this script.” 
    exit $NOTROOT
fi

display_help() {
    echo "Usage: $0 [option= ...] " >&2
    echo
    echo "   -h, --help              Show this help"
    echo "   -d, --domain            Set domain for certificate"
    echo "   -m, --email             Email for certificate"
    echo

    exit 1
}

for i in "$@"
do
case $i in
    -d=*|--domain=*)
    DOMAIN="${i#*=}"
    ;;
    -m=*|--email=*)
    EMAIL="${i#*=}"
    ;;
    -h=*|--help=*)
    display_help
    ;;
    *)
    # unknown option
    display_help
    ;;
esac
done

