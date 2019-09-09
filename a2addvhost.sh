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
PUBLIC_DIR_NAME=webroot
# WWW_ROOT=/home/dfsq/prog/sites/

# set defaults
DIRECTORY=/var/www
VHOST=localhost

for i in "$@"
do
case $i in
    -d=*|--directory=*)
    DIRECTORY="${i#*=}"
    ;;
    -u=*|--url=*)
    VHOST="${i#*=}"
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
mkdir -p -v $DIRECTORY"/"$PUBLIC_DIR_NAME
chown -R www-data:www-data $DIRECTORY

# 2. Make a copy of the new host configuration file
cp $VHOST_AVAILABLE"default" $VHOST_AVAILABLE$VHOST

# Extract default host path
default_path=`sed -n 's/.*DocumentRoot\s\(.*\)\s*/\1/p' $VHOST_AVAILABLE$VHOST`

# Server name
_s="ServerName\\s\\+.\\+"
_r="ServerName $VHOST"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST

# Write new DocumentRoot
_s=$default_path
_r=$DIRECTORY"/"$PUBLIC_DIR_NAME
_s="${_s//\//\\/}"
_r="${_r//\//\\/}"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST

# Change error.log path
_s="ErrorLog\\s\\+.\\+"
_r="ErrorLog "$VHOST"-error.log"
_r="${_r//\//\\/}"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST

# 4. Enable new host
a2ensite $VHOST

# 5. Update host file
echo -e "127.0.1.1\t$URL" >> /etc/hosts

# 6. Restart apache
/etc/init.d/apache2 reload

echo "Host $VHOST created."

exit;

END
