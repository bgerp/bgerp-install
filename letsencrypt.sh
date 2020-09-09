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
    echo "   -d, --domain            Set apache vhost for certificate"
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

extIP=`curl -s ifconfig.me`
echo "External IP: ${extIP}"

dnsIP=`dig +short "$d" @8.8.8.8`
echo "DNS IP: ${dnsIP}"

if [ "$extIP" = "$dnsIP" ]; then 
        echo "Let's encrypt OK ..."
        if ! grep -q "^deb .*certbot/certbot" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            echo Adding Certbot repository ...
            add-apt-repository -y ppa:certbot/certbot
            apt-get update
        fi
        if [ $(dpkg-query -W -f='${Status}' python-certbot-apache 2>/dev/null | grep -c "ok installed") -eq 0 ];
        then
            echo Installing Apache Certbot ... 
            apt-get install -y python-certbot-apache;
        fi
        # Installing certificate ...
        
    else
        echo "Let's encrypt failed: external IP is NOT equal to DNS IP."
fi



