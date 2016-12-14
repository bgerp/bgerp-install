export pass=111111

# Добавяме крон-а

crontab -l > cron.res
echo "* * * * * wget -q --spider --no-check-certificate http://localhost/core_Cron/cron" >> cron.res
crontab cron.res
rm cron.res


echo $pass | sudo -S apt-get update
#echo $pass | sudo -S apt-get -y upgrade
echo $pass | sudo -S apt-get install -y mysql-server
echo $pass | sudo -S apt-get install -y apache2 php5-mysql libapache2-mod-php5
# php7.0-mbstring

# настройки на апаче
echo $pass | sudo -S a2enmod headers
echo $pass | sudo -S a2enmod rewrite
echo $pass | sudo -S service apache2 restart


# php5-imap модул и други
echo $pass | sudo -S apt-get install -y php5-imap php5-curl php5-gd
echo $pass | sudo -S php5enmod imap
echo $pass | sudo -S service apache2 restart

# GIT
echo $pass | sudo -S apt-get install -y git
cd /var/www/
echo $pass | sudo -S git clone -b master http://github.com/bgerp/bgerp.git
echo $pass | sudo -S cp bgerp/_docs/webroot . -R
echo $pass | sudo -S cp bgerp/_docs/conf . -R
echo $pass | sudo -S mv conf/myapp.cfg.php conf/bgerp.cfg.php

# сменяме паролата на MySQL-a
mysqladmin -uroot password USER_PASSWORD_FOR_DB

# подменяме името на приложението и потребителя
echo $pass | sudo -S sed -i "s/DEFINE('EF_DB_NAME', EF_APP_NAME);/DEFINE('EF_DB_NAME', 'bgerp');/g" conf/bgerp.cfg.php
echo $pass | sudo -S sed -i "s/DEFINE('EF_DB_USER', EF_APP_NAME);/DEFINE('EF_DB_USER', 'root');/g" conf/bgerp.cfg.php

echo $pass | sudo -S sed -i "s/DEFINE('EF_USERS_HASH_FACTOR', 0);/DEFINE('EF_USERS_HASH_FACTOR', 400);/g" conf/bgerp.cfg.php
# коментираме солите - за да се създадат наново
echo $pass | sudo -S sed -i "s/DEFINE('EF_USERS_PASS_SALT', '');/#DEFINE('EF_USERS_PASS_SALT', '');/g" conf/bgerp.cfg.php
echo $pass | sudo -S sed -i "s/DEFINE('EF_SALT', '');/#DEFINE('EF_SALT', '');/g" conf/bgerp.cfg.php

# задаваме пътя до EF_ROOT и името на приложението
echo $pass | sudo -S sed -i "s/# DEFINE( 'EF_ROOT_PATH', 'PATH_TO_FOLDER');/DEFINE( 'EF_ROOT_PATH', '\/var\/www');/g" webroot/index.cfg.php
echo $pass | sudo -S sed -i "s/# DEFINE('EF_APP_NAME', 'APPLICATION_NAME');/DEFINE('EF_APP_NAME', 'bgerp');/g" webroot/index.cfg.php

echo $pass | sudo -S chown www-data:www-data /var/www -R

# Настрoйваме хоста по подразбиране 
echo $pass | sudo -S sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/webroot \n<Directory \/var\/www\/webroot\/>\n Options FollowSymLinks\n  AllowOverride All\n  Require all granted\n<\/Directory>/g" /etc/apache2/sites-enabled/000-default.conf

echo $pass | sudo -S service apache2 restart


# Допълнителен софтуер
echo $pass | sudo -S apt-get install -y wkhtmltopdf
echo $pass | sudo -S apt-get install -y xvfb
echo $pass | sudo -S apt-get install -y ghostscript
echo $pass | sudo -S apt-get install -y imagemagick
echo $pass | sudo -S apt-get install -y zbar-tools
echo $pass | sudo -S apt-get install -y swftools
echo $pass | sudo -S apt-get install -y xpdf-utils
echo $pass | sudo -S apt-get install -y p7zip-full
echo $pass | sudo -S apt-get install -y default-jre
echo $pass | sudo -S apt-get install -y unoconv

echo $pass | sudo -S sudo add-apt-repository ppa:inkscape.dev/stable
echo $pass | sudo -S sudo apt-get update
echo $pass | sudo -S apt-get install -y inkscape
echo $pass | sudo -S sudo apt-get install -y tnef
