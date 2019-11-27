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
    echo "   -d, --directory            Set bgERP dirertory to install /EF_ROOT_PATH/"
    echo "   -u, --url                  Apache virtual host name"
    echo "   -b, --branch               bgERP source git branch"
    echo "   -n, --dbname               MySQL database name"
    echo "   -p, --dbrootpass           password for MySQL root user"
    echo "   -s, --dbusername           database user name"
    echo "   -a, --dbuserpass           database user password"
    echo "   -m, --mysqlhost            MySQL host address"
    echo "   -c, --config               Config file for first user, email, company"
    echo

    exit 1
}

# set defaults
DIRECTORY=/var/www
VHOST=localhost
BRANCH=master
DBNAME=bgerp
DBROOTPASS=32D234d#$
DBUSERNAME=bgerp
DBUSERPASS= # will be randomly generated
MYSQLHOST=localhost

for i in "$@"
do
case $i in
    -d=*|--directory=*)
    DIRECTORY="${i#*=}"
    ;;
    -u=*|--url=*)
    VHOST="${i#*=}"
    ;;
    -b=*|--branch=*)
    BRANCH="${i#*=}"
    ;;
    -n=*|--dbname=*)
    DBNAME="${i#*=}"
    ;;
    -p=*|--dbrootpass=*)
    DBROOTPASS="${i#*=}"
    ;;
    -s=*|--dbusername=*)
    DBUSERNAME="${i#*=}"
    ;;
    -a=*|--dbuserpass=*)
    DBUSERPASS="${i#*=}"
    ;;
    -m=*|--mysqlhost=*)
    MYSQLHOST="${i#*=}"
    ;;
    -c=*|--config=*)
    MYSQLHOST="${i#*=}"
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

# instalation info
echo Instalation info:
echo DIRECTORY = ${DIRECTORY}
echo VHOST = ${VHOST}
echo BRANCH = ${BRANCH}
echo DBNAME = ${DBNAME}
echo DBROOTPASS = ${DBROOTPASS}
echo DBUSERNAME = ${DBUSERNAME}
echo DBUSERPASS = ${DBUSERPASS} # will be randomly generated
echo MYSQLHOST = ${MYSQLHOST}

echo "Ctrl-C to cancel ..."
secs=$((7))
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done

dpkg -s apache2 &> /dev/null

if [ $? -eq 0 ]; then
    echo "Package apache2 is installed."
else
    echo "Package apache2 is NOT installed! Installing ..."
    apt-get install -y apache2
fi

# настройки на апаче
a2enmod headers
a2enmod rewrite

bash a2addvhost.sh -d=${DIRECTORY} -u=${VHOST}

add-apt-repository -y ppa:ondrej/php
apt-get install software-properties-common
add-apt-repository -y ppa:inkscape.dev/stable
apt-get update
apt-get -y upgrade
apt-get install -y mysql-server php7.0-mysqlnd libapache2-mod-php7.0 php7.0-mbstring php7.0-mysqlnd php7.0-imap php7.0-curl php7.0-gd php7.0-soap php7.0-xml php7.0-zip php7.0-pspell aspell-en aspell-bg tesseract-ocr tesseract-ocr-bul openssl webp

phpenmod imap  
service apache2 restart

# GIT
apt-get install -y git
cd ${DIRECTORY}
git clone -b ${BRANCH} http://github.com/bgerp/bgerp.git
cp bgerp/_docs/webroot . -R
cp bgerp/_docs/conf . -R
mv conf/myapp.cfg.php conf/bgerp.cfg.php

# сменяме паролата на MySQL-a
mysqladmin -uroot password ${DBROOTPASS}

# Ако не е зададена - генерираме 6 символна парола за потребителя
[[  -z  ${DBUSERPASS}  ]] && DBUSERPASS=`openssl rand -base64 32` && DBUSERPASS=${DBUSERPASS:3:6}

cat > /tmp/mysqldb.sql << EOF
CREATE DATABASE ${DBNAME};
GRANT ALL ON ${DBNAME}.* TO ${DBUSERNAME}@localhost IDENTIFIED BY '${DBUSERPASS}';
EOF

mysql -uroot -p${DBROOTPASS} < /tmp/mysqldb.sql
rm /tmp/mysqldb.sql


# подменяме името на приложението и потребителя
sed -i "s/DEFINE('EF_DB_NAME', EF_APP_NAME);/DEFINE('EF_DB_NAME', '${DBNAME}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_USER', EF_APP_NAME);/DEFINE('EF_DB_USER', '${DBUSERNAME}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_PASS', 'USER_PASSWORD_FOR_DB');/DEFINE('EF_DB_PASS', '${DBUSERPASS}');/g" conf/bgerp.cfg.php

sed -i "s/DEFINE('EF_USERS_HASH_FACTOR', 0);/DEFINE('EF_USERS_HASH_FACTOR', 400);/g" conf/bgerp.cfg.php
# коментираме солите - за да се създадат наново
sed -i "s/DEFINE('EF_USERS_PASS_SALT', '');/#DEFINE('EF_USERS_PASS_SALT', '');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_SALT', '');/#DEFINE('EF_SALT', '');/g" conf/bgerp.cfg.php

sed -i "s/DEFINE('BGERP_GIT_BRANCH', 'master');/DEFINE('BGERP_GIT_BRANCH', '${BRANCH}');/g" conf/bgerp.cfg.php

# задаваме пътя до EF_ROOT и името на приложението
sed -i "s/# DEFINE('EF_ROOT_PATH', '\[#PATH_TO_FOLDER#\]');/DEFINE( 'EF_ROOT_PATH', '"${DIRECTORY//\//\\/}"');/g" webroot/index.cfg.php
sed -i "s/# DEFINE('EF_APP_NAME', 'bgerp');/DEFINE('EF_APP_NAME', 'bgerp');/g" webroot/index.cfg.php

chown www-data:www-data ${DIRECTORY} -R

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
apt-get install -y timelimit


apt-get install -y inkscape
apt-get install -y tnef

apt install jpegoptim
apt install libjpeg-turbo-progs
apt install optipng
apt install pngquant

crontab -l > cron.res
echo "* * * * * wget -q --spider --no-check-certificate http://"${VHOST}"/core_Cron/cron" >> cron.res
crontab cron.res
rm cron.res
