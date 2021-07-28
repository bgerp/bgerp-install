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
    echo "   -h, --help                Show this help"
    echo "   -v, --vhost               Apache virtual host name"
    echo "   -n, --newvhost            New Apache virtual host name"
    echo

    exit 1
}


VHOST_AVAILABLE=/etc/apache2/sites-available/

for i in "$@"
do
case $i in
    -n=*|--newvhost=*)
    NEWVHOST="${i#*=}"
    ;;
    -v=*|--vhost=*)
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

vdomain_file_name=`grep "ServerName $VHOST" $VHOST_AVAILABLE* | grep -v -e "#"`

[ -z "$vdomain_file_name" ] && echo "Source virtual host is not found!" && exit 1


vdomain_file_name=${vdomain_file_name%:*}

# copy as new virtual name file
cp $vdomain_file_name $VHOST_AVAILABLE$NEWVHOST.conf
sed -i 's/ServerName $VHOST/ServerName $NEWVHOST/g' $VHOST_AVAILABLE$NEWVHOST.conf 

# Change error.log path
_s="$VHOST-error.log"
_r="$NEWVHOST-error.log"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST".conf"

# Change access.log path
_s="$VHOST-access.log"
_r="$NEWVHOST-access.log"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST".conf"


# 4. Enable new host
a2ensite $NEWVHOST

# 5. Update host file
echo -e "127.0.1.1\t$NEWVHOST" >> /etc/hosts

# 6. Restart apache
/etc/init.d/apache2 reload

echo "Host $VHOST cloned to $NEWVHOST."

exit;
