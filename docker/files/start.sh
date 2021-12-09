#!/bin/bash
##
set -e

##Init
#
echo "Init ..."

if [[ ! -d "/var/www/mount/sbf" ]] 
then
    ls -la /var/www/
    ls -la /var/www/mount/
    echo "Creating /var/www/mount/sbf ..."
    mkdir /var/www/mount/sbf
    ln -s /var/www/mount/sbf /var/www/html/sbf
    echo "Creating /var/www/mount/uploads ..."
    mkdir /var/www/mount/uploads
    ln -s /var/www/mount/uploads /var/www/uploads
    echo "Creating /var/www/mount/.config ..."
    mkdir /var/www/mount/.config
    ln -s /var/www/mount/.config /var/www/.config
    echo "Creating /var/www/mount/.cache ..."
    mkdir /var/www/mount/.cache
    ln -s /var/www/mount/.cache /var/www/.cache
fi


if [ -z ${APP_ENV+x} ]; then echo "No APP_ENV"; export APP_ENV="test"; fi 
#
echo "Env "$APP_ENV
if [ $APP_ENV = "dev" ]; then
    echo "."
    echo "Enabling Xdebug"
    echo "zend_extension=xdebug.so"  >  /etc/php/7.3/apache2/99-xdebug.ini
    echo "[Xdebug]"                  >> /etc/php/7.3/apache2/99-xdebug.ini
    echo "xdebug.remote_enable=true" >> /etc/php/7.3/apache2/99-xdebug.ini
    echo "xdebug.remote_port=5902"   >> /etc/php/7.3/apache2/99-xdebug.ini
    echo "xdebug.remote_autostart = 1"  >> /etc/php/7.3/apache2/99-xdebug.ini
    echo "xdebug.remote_host=localhost"  >> /etc/php/7.3/apache2/99-xdebug.ini 
    #echo "xdebug.default_enable=1"   >>
    #echo "xdebug.remote_handler = dbgp" >>   
elif [ $APP_ENV = "test" ]; then
    echo "Test env ..."
else
	echo "."
fi
#
echo "Configuring Apache ..."
: "${APACHE_CONFDIR:=/etc/apache2}"
: "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
if test -f "$APACHE_ENVVARS"; then
	. "$APACHE_ENVVARS"
fi

: "${APACHE_RUN_DIR:=/var/run/apache2}"
: "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
rm -f "$APACHE_PID_FILE"
#
echo "Starting Apache ..."
exec /usr/sbin/apache2 -DFOREGROUND
