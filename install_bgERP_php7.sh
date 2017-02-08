#!/bin/bash 
crontab -l > cron.res
echo "* * * * * wget -q --spider --no-check-certificate http://localhost/core_Cron/cron" >> cron.res
crontab cron.res
rm cron.res

apt-get update
apt-get -y upgrade
apt-get install -y mysql-server apache2 php-mysql libapache2-mod-php php-mbstring php-mysqlnd php-imap php-curl php-gd php-soap php-xml php7.0-zip pspell aspell-bg tesseract-ocr tesseract-ocr-bul 
phpenmod imap

# настройки на апаче
a2enmod headers
a2enmod rewrite
service apache2 restart

# GIT
apt-get install -y git
cd /var/www/
git clone -b master http://github.com/bgerp/bgerp.git
cp bgerp/_docs/webroot . -R
cp bgerp/_docs/conf . -R
mv conf/myapp.cfg.php conf/bgerp.cfg.php

# сменяме паролата на MySQL-a
mysqladmin -uroot password USER_PASSWORD_FOR_DB

# подменяме името на приложението и потребителя
sed -i "s/DEFINE('EF_DB_NAME', EF_APP_NAME);/DEFINE('EF_DB_NAME', 'bgerp');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_USER', EF_APP_NAME);/DEFINE('EF_DB_USER', 'root');/g" conf/bgerp.cfg.php

sed -i "s/DEFINE('EF_USERS_HASH_FACTOR', 0);/DEFINE('EF_USERS_HASH_FACTOR', 400);/g" conf/bgerp.cfg.php
# коментираме солите - за да се създадат наново
sed -i "s/DEFINE('EF_USERS_PASS_SALT', '');/#DEFINE('EF_USERS_PASS_SALT', '');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_SALT', '');/#DEFINE('EF_SALT', '');/g" conf/bgerp.cfg.php

# задаваме пътя до EF_ROOT и името на приложението
sed -i "s/# DEFINE( 'EF_ROOT_PATH', 'PATH_TO_FOLDER');/DEFINE( 'EF_ROOT_PATH', '\/var\/www');/g" webroot/index.cfg.php
sed -i "s/# DEFINE('EF_APP_NAME', 'APPLICATION_NAME');/DEFINE('EF_APP_NAME', 'bgerp');/g" webroot/index.cfg.php

chown www-data:www-data /var/www -R

# Настрoйваме хоста по подразбиране 
sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/webroot \n<Directory \/var\/www\/webroot\/>\n Options FollowSymLinks\n  AllowOverride All\n  Require all granted\n<\/Directory>/g" /etc/apache2/sites-enabled/000-default.conf

service apache2 restart

# Допълнителен софтуер
apt-get install -y wkhtmltopdf
apt-get install -y xvfb
apt-get install -y ghostscript
apt-get install -y imagemagick
apt-get install -y zbar-tools
apt-get install -y swftools
apt-get install -y xpdf-utils
apt-get install -y p7zip-full
apt-get install -y p7zip-rar
apt-get install -y default-jre
apt-get install -y unoconv

apt-get install software-properties-common
add-apt-repository ppa:inkscape.dev/stable
apt-get update
apt-get install -y inkscape
apt-get install -y tnef

apt install jpegoptim
apt install libjpeg-turbo-progs
apt install optipng
apt install pngquant
