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
    echo "   -h, --help                 Show this help"
    echo "   -d, --directory            Set bgERP dirertory to install"
    echo "   -u, --url                  Apache virtual host name"
    echo

    exit 1
}


VHOST_AVAILABLE=/etc/apache2/sites-available/
# WWW_ROOT=/home/dfsq/prog/sites/
# PUBLIC_DIR_NAME=webroot

# set defaults
DIRECTORY=/var/www
URL=localhost

for i in "$@"
do
case $i in
    -d=*|--directory=*)
    DIRECTORY="${i#*=}"
    ;;
    -u=*|--url=*)
    URL="${i#*=}"
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

# 1. Create new host directory
mkdir -p -v $WWW_ROOT$URL"/"$PUBLIC_DIR_NAME
chown -R www-data:www-data $WWW_ROOT$URL

# 2. Make a copy of the new host configuration file
cp $VHOST_AVAILABLE"default" $VHOST_AVAILABLE$URL

# Extract default host path
default_path=`sed -n 's/.*DocumentRoot\s\(.*\)\s*/\1/p' $VHOST_AVAILABLE$URL`

# Server name
_s="ServerName\\s\\+.\\+"
_r="ServerName $URL"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$URL

# Write new DocumentRoot
_s=$default_path
_r=$WWW_ROOT$URL"/"$PUBLIC_DIR_NAME
_s="${_s//\//\\/}"
_r="${_r//\//\\/}"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$URL

# Change error.log path
_s="ErrorLog\\s\\+.\\+"
_r="ErrorLog "$WWW_ROOT$URL"/error.log"
_r="${_r//\//\\/}"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$URL

# 4. Enable new host
a2ensite $URL

# 5. Update host file
echo -e "127.0.1.1\t$URL" >> /etc/hosts

# 6. Restart apache
/etc/init.d/apache2 reload

echo "Host $URL created."

exit;

END
