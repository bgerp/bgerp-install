#!/bin/bash

ROOT_UID=0
NOTROOT=87

# Check if user is root
if [ $UID -ne $ROOT_UID ]
    then echo “You must be root to run this script.” 
    exit $NOTROOT
fi

# Основна проверка за Ubuntu
if ! grep -iq "ubuntu" /etc/os-release; then
  echo "Error: This script is designed to run on an Ubuntu Server only"
  exit 1
else
  # Проверка за версиата на Ubuntu
  ubuntu_version=$(grep "VERSION=" /etc/os-release | sed 's/VERSION=//g' | tr -d '"')

  # Показване на версията на Ubuntu
  echo "This system is running Ubuntu. Version details: $ubuntu_version"
fi

# Провери дали curl e инсталиран
if ! command -v curl &> /dev/null; then
    apt-get install -y curl
    if [ $? -eq 0 ]; then
        echo "curl installed successfully."
    else
        echo "Failed to install curl. Please check your system configuration."
        exit 1
    fi
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
        echo "Let's encrypt Ips OK ..."
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
        if [ -z "$m" ];
        then
            certbot --noninteractive --agree-tos -n "$m" --apache -d "$d"
        else
            certbot --noninteractive --agree-tos --register-unsafely-without-email --apache -d "$d"
        fi
    else
        echo "Let's encrypt failed: external IP is NOT equal to DNS IP."
fi



