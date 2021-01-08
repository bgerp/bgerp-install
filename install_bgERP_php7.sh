#!/bin/bash 

echo " _           ______ _____  _____    _____           _        _ _ "
echo "| |         |  ____|  __ \|  __ \  |_   _|         | |      | | |"
echo "| |__   __ _| |__  | |__) | |__) |   | |  _ __  ___| |_ __ _| | |"
echo "| '_ \ / _\` |  __| |  _  /|  ___/    | | | '_ \/ __| __/ _\` | | |"
echo "| |_) | (_| | |____| | \ \| |       _| |_| | | \__ \ || (_| | | |"
echo "|_.__/ \__, |______|_|  \_\_|      |_____|_| |_|___/\__\__,_|_|_|"
echo "        __/ |                                                    "
echo "       |___/                                                     "
echo "_________________________________________________________________"


ROOT_UID=0
NOTROOT=87
# Check if user is root
if [ $UID -ne $ROOT_UID ]
    then echo “You will need to be root or use sudo to start this instalation” 
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
    echo "   -l, --cert                 Let's encrypt certificate - yes/no"
    echo "   -e, --certemail            Let's encrypt email"
    echo

    exit 1
}

# set defaults
DIRECTORY=/var/www
VHOST=localhost
BRANCH=master
DBNAME=bgerp
DBROOTPASS= # if not set by user will be randomly generated 
DBUSERNAME=bgerp
DBUSERPASS= # if not set by user will be randomly generated
MYSQLHOST=localhost
ABSCLONEPATH="`pwd -P`/a2clonevhost.sh"

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
    -l=*|--cert=*)
    CERT="${i#*=}"
    ;;
    -e=*|--certemail=*)
    CERTEMAIL="${i#*=}"
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
echo Installation information for bgERP:
echo DIRECTORY = ${DIRECTORY}
echo VHOST = ${VHOST}
echo BRANCH = ${BRANCH}
echo DBNAME = ${DBNAME}
echo DBROOTPASS = ${DBROOTPASS} # will be randomly generated
echo DBUSERNAME = ${DBUSERNAME}
echo DBUSERPASS = ${DBUSERPASS} # will be randomly generated
echo MYSQLHOST = ${MYSQLHOST}
echo CERT = ${CERT}
echo CERTEMAIL = ${CERTEMAIL}

echo "Ctrl-C to cancel ..."
secs=$((10))
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done

echo "The installation of bgERP has started. Please be patient. "

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

if [ $? -eq -1 ]
then
  echo "Directory for virtual host is not empty!"
  exit -1
fi

apt-get update
apt-get -y upgrade
apt-get install -y mariadb-server php-mysqlnd libapache2-mod-php php-mbstring php-mysqlnd php-imap php-curl php-gd php-soap php-xml php-zip php-pspell aspell-en aspell-bg tesseract-ocr tesseract-ocr-bul openssl webp git

phpenmod imap  
service apache2 restart

cd ${DIRECTORY}
git clone -b ${BRANCH} https://github.com/bgerp/bgerp.git
cp bgerp/_docs/webroot . -R
cp bgerp/_docs/conf . -R
mv conf/myapp.cfg.php conf/bgerp.cfg.php

# Ако не е зададена - генерираме 6 символна парола за root потребителя на MySQL-a
[[  -z  ${DBROOTPASS}  ]] && DBROOTPASS=`openssl rand -base64 32` && DBROOTPASS=${DBROOTPASS//\/\//} && DBROOTPASS=${DBUSERPASS:3:6}
# сменяме паролата на MySQL-a
mysqladmin -uroot password ${DBROOTPASS}


# Ако не е зададена - генерираме 6 символна парола за потребителя
[[  -z  ${DBUSERPASS}  ]] && DBUSERPASS=`openssl rand -base64 32` && DBUSERPASS=${DBUSERPASS//\/\//} && DBUSERPASS=${DBUSERPASS:3:6} 

cat > /tmp/mysqldb.sql << EOF
CREATE DATABASE ${DBNAME};
CREATE USER ${DBUSERNAME}@localhost IDENTIFIED BY '${DBUSERPASS}';
GRANT ALL ON ${DBNAME}.* TO ${DBUSERNAME}@localhost;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

mysql -uroot -p${DBROOTPASS} < /tmp/mysqldb.sql
rm /tmp/mysqldb.sql


# подменяме името на приложението, потребителя и домейна по подразбиране
sed -i "s/DEFINE('EF_DB_NAME', EF_APP_NAME);/DEFINE('EF_DB_NAME', '${DBNAME}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_USER', EF_APP_NAME);/DEFINE('EF_DB_USER', '${DBUSERNAME}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_PASS', 'USER_PASSWORD_FOR_DB');/DEFINE('EF_DB_PASS', '${DBUSERPASS}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('BGERP_VHOST', 'localhost');/DEFINE('BGERP_VHOST', '${VHOST}');/g" conf/bgerp.cfg.php
# субституираме абсолютното име скрипта в bgERP-a
sed -i "s/DEFINE('BGERP_CLONE_VHOST_SCRIPT','');/DEFINE('BGERP_VHOST', '${ABSCLONEPATH}');/g" conf/bgerp.cfg.php

sed -i "s/DEFINE('EF_USERS_HASH_FACTOR', 0);/DEFINE('EF_USERS_HASH_FACTOR', 400);/g" conf/bgerp.cfg.php
# задаваме солите със случайни стрингове
PASS_SALT=$( cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
sed -i "s/DEFINE('EF_USERS_PASS_SALT', '');/DEFINE('EF_USERS_PASS_SALT', '${PASS_SALT}');/g" conf/bgerp.cfg.php
EF_SALT=$( cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
sed -i "s/DEFINE('EF_SALT', '');/DEFINE('EF_SALT', '${EF_SALT}');/g" conf/bgerp.cfg.php

sed -i "s/DEFINE('BGERP_GIT_BRANCH', 'master');/DEFINE('BGERP_GIT_BRANCH', '${BRANCH}');/g" conf/bgerp.cfg.php

# задаваме пътя до EF_ROOT и името на приложението
sed -i "s/# DEFINE('EF_ROOT_PATH', '\[#PATH_TO_FOLDER#\]');/DEFINE( 'EF_ROOT_PATH', '"${DIRECTORY//\//\\/}"');/g" webroot/index.cfg.php
sed -i "s/# DEFINE('EF_APP_NAME', 'bgerp');/DEFINE('EF_APP_NAME', 'bgerp');/g" webroot/index.cfg.php

chown www-data:www-data ${DIRECTORY} -R

# Допълнителен софтуер
apt install -y wkhtmltopdf
apt install -y xvfb
apt install -y ghostscript
apt install -y imagemagick
apt install -y zbar-tools
apt install -y xpdf-utils
apt install -y p7zip-full
apt install -y p7zip-rar
apt install -y default-jre
apt install -y unoconv
apt install -y timelimit

apt install -y inkscape
apt install -y tnef

apt install -y jpegoptim
apt install -y libjpeg-turbo-progs
apt install -y optipng
apt install -y pngquant
apt install -y wget

# добавяне на a2clonevhost.sh апаче да може да го изпълнява като sudo-ер
    #chmod u+w /etc/sudoers
    #echo "www-data ALL=(ALL) NOPASSWD: $(dirname "$0")\/\a2clonevhost.sh" >> /etc/sudoers 

    #chmod u-w /etc/sudoers

crontab -l > cron.res
echo "* * * * * wget -q --spider --no-check-certificate http://"${VHOST}"/core_Cron/cron" >> cron.res
crontab cron.res
rm cron.res

if [[ $CERT ]]; then
    echo "Installing Let's Encrypt ..."
    bash letsencrypt.sh -d=${VHOST} -m=${CERTEMAIL}
else
    echo "Not ssl certificate will be installed."
fi

# Create instalation info file
echo "Installation information for bgERP" > ~/bgerp-install.info
echo "==================================" >> ~/bgerp-install.info
echo "DIRECTORY = "${DIRECTORY} >> ~/bgerp-install.info
echo "VHOST = "${VHOST} >> ~/bgerp-install.info
echo "BRANCH = "${BRANCH} >> ~/bgerp-install.info
echo "DBNAME = "${DBNAME} >> ~/bgerp-install.info
echo "DBROOTPASS = "${DBROOTPASS} >> ~/bgerp-install.info
echo "DBUSERNAME = "${DBUSERNAME} >> ~/bgerp-install.info
echo "DBUSERPASS = "${DBUSERPASS} >> ~/bgerp-install.info
echo "MYSQLHOST = "${MYSQLHOST} >> ~/bgerp-install.info

echo *****************************************************************
echo The bgERP system is installed on this server. To open it,   
echo "load in the browser http://"${VHOST}". The installation"      
echo parameters are saved in the file /root/bgerp-install.info   
echo *****************************************************************

cat ~/bgerp-install.info
