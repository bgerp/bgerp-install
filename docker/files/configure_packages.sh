#!/bin/bash
set -e
###########
# PHP
###########
cp -f /tmp/php.ini /etc/php/7.3/apache2/
touch /etc/php/7.3/apache2/99-xdebug.ini
chmod o+w /etc/php/7.3/apache2/99-xdebug.ini
#
ln -snf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone
echo "date.timezone = UTC" >> /etc/php/7.3/cli/conf.d/php.ini
echo "date.timezone = UTC" >> /etc/php/7.3/apache2/php.ini
echo 'opcache.memory_consumption=128' >>/etc/php/7.3/apache2/conf.d/45-opcache-recommended.ini 
echo 'opcache.interned_strings_buffer=8' >>/etc/php/7.3/apache2/conf.d/45-opcache-recommended.ini 
echo 'opcache.max_accelerated_files=4000'>>/etc/php/7.3/apache2/conf.d/45-opcache-recommended.ini 
echo 'opcache.revalidate_freq=2' >>/etc/php/7.3/apache2/conf.d/45-opcache-recommended.ini
echo 'opcache.fast_shutdown=1' >>/etc/php/7.3/apache2/conf.d/45-opcache-recommended.ini 
echo 'mysqli.default_socket="/tmp/mysql.sock"' >> /etc/php/7.3/apache2/conf.d/50-mysql-recommended.ini


###########
# Apache
###########
mkdir -p /var/run/apache2
chown www-data:www-data /var/run/apache2
ln -sfT /dev/stderr "/var/log/apache2/error.log"
ln -sfT /dev/stdout "/var/log/apache2/access.log"
ln -sfT /dev/stdout "/var/log/apache2/other_vhosts_access.log"
chown -R --no-dereference "www-data:www-data" "/var/log/apache2"
#
sed -ri 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g;  s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g;' /etc/apache2/apache2.conf
sed -ri 's/80/8080/' /etc/apache2/ports.conf

#these IP ranges are reserved for "private" use and should thus *usually* be safe inside Docker
echo 'RemoteIPHeader X-Forwarded-For'       >> /etc/apache2/conf-available/remoteip.conf 
echo 'RemoteIPTrustedProxy 10.0.0.0/8'      >> /etc/apache2/conf-available/remoteip.conf 
echo 'RemoteIPTrustedProxy 172.16.0.0/12'   >> /etc/apache2/conf-available/remoteip.conf 
echo 'RemoteIPTrustedProxy 192.168.0.0/16'  >> /etc/apache2/conf-available/remoteip.conf 
echo 'RemoteIPTrustedProxy 169.254.0.0/16'  >> /etc/apache2/conf-available/remoteip.conf 
echo 'RemoteIPTrustedProxy 127.0.0.0/8'     >> /etc/apache2/conf-available/remoteip.conf 
a2enconf remoteip
#
rm -f /etc/apache2/sites-enabled/*
cp -f /tmp/default.conf /etc/apache2/sites-enabled/default.conf 


###########
# BgErp
###########
shopt -s dotglob
cp /var/www/bgerp/_docs/webroot/* /var/www/html/ -R
cp /var/www/bgerp/_docs/conf/ /var/www/ -R
mv /var/www/conf/myapp.cfg.php /var/www/conf/bgerp.cfg.php
cat <<EOF >> /var/www/html/.htaccess

<IfModule mod_deflate.c>
AddOutputFilter DEFLATE php

AddDefaultCharset UTF-8

# Upload large files
php_value upload_max_filesize 1000M
php_value post_max_size 1500M
php_value xdebug.max_nesting_level 500
EOF

rm -rf /var/www/bgerp/.git
rm -f  /var/www/html/index.html
mkdir /var/www/mount/
chown -R www-data. /var/www/

# Conf from env variables.
# подменяме името на приложението, потребителя и домейна по подразбиране
sed -i "s/DEFINE('EF_DB_HOST', 'localhost');/DEFINE('EF_DB_HOST', getenv('DBHOST'));/g" /var/www/conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_NAME', EF_APP_NAME);/DEFINE('EF_DB_NAME', getenv('DBNAME'));/g" /var/www/conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_USER', EF_APP_NAME);/DEFINE('EF_DB_USER', getenv('DBUSERNAME'));/g" /var/www/conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_PASS', 'USER_PASSWORD_FOR_DB');/DEFINE('EF_DB_PASS', getenv('DBUSERPASS'));/g" /var/www/conf/bgerp.cfg.php
sed -i "s/DEFINE('BGERP_VHOST', 'localhost');/DEFINE('BGERP_VHOST', getenv('VHOST'));/g" /var/www/conf/bgerp.cfg.php
# субституираме абсолютното име скрипта в bgERP-a
sed -i "s/DEFINE('BGERP_CLONE_VHOST_SCRIPT','');/DEFINE('BGERP_VHOST', getenv('ABSCLONEPATH'));/g" /var/www/conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_USERS_HASH_FACTOR', 0);/DEFINE('EF_USERS_HASH_FACTOR', 200);/g" /var/www/conf/bgerp.cfg.php
# задаваме солите със случайни стрингове
sed -i "s/DEFINE('EF_USERS_PASS_SALT', '');/DEFINE('EF_USERS_PASS_SALT', getenv('PASS_SALT'));/g" /var/www/conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_SALT', '');/DEFINE('EF_SALT', getenv('EF_SALT'));/g" /var/www/conf/bgerp.cfg.php
sed -i "s/DEFINE('BGERP_GIT_BRANCH', 'master');/DEFINE('BGERP_GIT_BRANCH', getenv('BRANCH'));/g" /var/www/conf/bgerp.cfg.php
# задаваме пътя до EF_ROOT и името на приложението
sed -i "s/# DEFINE('EF_ROOT_PATH', '\[#PATH_TO_FOLDER#\]');/DEFINE( 'EF_ROOT_PATH', '\/var\/www\/');/g" /var/www/html/index.cfg.php
sed -i "s/# DEFINE('EF_APP_NAME', 'bgerp');/DEFINE('EF_APP_NAME', 'bgerp');/g" /var/www/html/index.cfg.php

###########
# StartUP
###########
chown root:root  /tmp/start.sh
chmod 0555 /tmp/start.sh
