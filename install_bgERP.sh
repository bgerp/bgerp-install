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

# Проверка дали скрипта е стартиран като root потребител
if [ $UID -ne $ROOT_UID ]
    then echo “You will need to be root or use sudo to start this instalation” 
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
  echo "UBUNTU: $ubuntu_version"
fi

# Функция за помощно меню
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
    echo "   -f, --php-mode             PHP handler: apache (default) or fpm"
    echo

    exit 1
}

# Задаване на стойности на нужните параметри по подразбиране
DIRECTORY=/var/www
VHOST=localhost
BRANCH=master
DBNAME=bgerp
DBROOTPASS= # ако не е зададена от потребителя, ще се генерира на случаен принцип
DBUSERNAME=bgerp
DBUSERPASS= # ако не е зададена от потребителя, ще се генерира на случаен принцип
MYSQLHOST=localhost
PHP_MODE=apache

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
    -f=*|--php-mode=*)
    PHP_MODE="${i#*=}"
    ;;
    -h|--help|-h=*|--help=*)
    display_help
    ;;
    *)
    # непозната опция
    display_help
    ;;
esac
done

case "$PHP_MODE" in
    apache|fpm) ;;
    *)
    echo "Error: --php-mode must be apache or fpm." >&2
    exit 1
    ;;
esac

# Показване на информация за параметрите на настоящата инсталация
echo Installation information for bgERP:
echo DIRECTORY = ${DIRECTORY}
echo VHOST = ${VHOST}
echo BRANCH = ${BRANCH}
echo DBNAME = ${DBNAME}
echo DBROOTPASS = ${DBROOTPASS} # паролата ще бъде генерирана на случаен принцип
echo DBUSERNAME = ${DBUSERNAME}
echo DBUSERPASS = ${DBUSERPASS} # паролата ще бъде генерирана на случаен принцип
echo MYSQLHOST = ${MYSQLHOST}
echo PHP_MODE = ${PHP_MODE}

echo "Ctrl-C to cancel ..."
secs=$((10))
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done

echo "The installation of bgERP has started. Please be patient. "

# Запазване на директорията, от която е стартиран скриптът
START_DIR=$(pwd)

# Актуализиране на системните пакети
apt-get update
apt-get -y upgrade

TIMEZONE="Europe/Sofia"
timedatectl set-timezone "$TIMEZONE"
echo "Timezone set to: $(timedatectl show -p Timezone --value)"

# Проверка дали има инсталиран MariaDB и са налице нужните разрешения
F=`which mysql`
if [ ! -f "$F" ] ; then
        # install mariadb server
    apt-get install -y mariadb-server
    else
    # проверка на разрешенията
    RES=`mysql -uroot -p${DBROOTPASS} -e"show databases" | grep -o ${DBNAME} 2>&1`
    if [ "${DBNAME}" = "${RES}" ]; then
    	echo "DBNAME exists! -- ${DBNAME}. Use other DBNAME name. Installation stopped."
    	exit 0
    fi
    # проверка за съществуващ потребител на базата данни
    RES=`mysql -uroot -p${DBROOTPASS} --skip-column-names -e"SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${DBUSERNAME}')"`
	if [ ${RES} = 1 ]; then
		echo "DBUSERNAME exists! -- ${DBUSERNAME}. Use other DBUSERNAME name. Installation stopped."
    	exit 0
	fi 
fi



dpkg -s apache2 &> /dev/null

if [ $? -eq 0 ]; then
    echo "Package apache2 is installed."
else
    echo "Package apache2 is NOT installed! Installing ..."
    apt-get install -y apache2
fi

# Настройки на Апаче
a2enmod headers
a2enmod rewrite
a2enmod ssl
a2enmod allowmethods

bash a2addvhost.sh -d=${DIRECTORY} -u=${VHOST} -s=yes

if [ $? -eq -1 ]
then
  echo "Directory for virtual host is not empty!"
  exit -1
fi

. /etc/os-release
PHP_VERSION=

if [ "$VERSION_ID" = "24.04" ]; then
		# Ubuntu 24.04 - инсталира php 7.4
		PHP_VERSION=7.4
		apt install software-properties-common
		add-apt-repository ppa:ondrej/php -y
		
	elif [ "$VERSION_ID" = "26.04" ]; then
		# Ubuntu 26.04 - инсталира php 8.2
		PHP_VERSION=8.2
		apt install -y ca-certificates curl lsb-release apt-transport-https gnupg
		curl -fsSL https://packages.sury.org/php/apt.gpg \
  		| gpg --dearmor -o /usr/share/keyrings/debsuryorg-archive-keyring.gpg
		echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
  		| tee /etc/apt/sources.list.d/php-sury.list
		# wkhtmltox - install
		apt install -y fontconfig xfonts-base xfonts-75dpi libxrender1 libxext6 libjpeg-turbo8
		wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
		apt update		
        apt install -y ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb  		
		
fi

PHP_PACKAGE="php${PHP_VERSION}"
PHP_HANDLER_PACKAGE="libapache2-mod-${PHP_PACKAGE}"
PHP_SAPI=apache2
if [ "$PHP_MODE" = "fpm" ]; then
    PHP_HANDLER_PACKAGE="${PHP_PACKAGE}-fpm"
    PHP_SAPI=fpm
fi

apt-get install -y "$PHP_HANDLER_PACKAGE" "${PHP_PACKAGE}-cli" \
    "${PHP_PACKAGE}-mysql" "${PHP_PACKAGE}-mbstring" "${PHP_PACKAGE}-imap" \
    "${PHP_PACKAGE}-curl" "${PHP_PACKAGE}-apcu" "${PHP_PACKAGE}-gd" \
    "${PHP_PACKAGE}-soap" "${PHP_PACKAGE}-xml" "${PHP_PACKAGE}-zip" \
    "${PHP_PACKAGE}-pspell" "${PHP_PACKAGE}-ssh2" \
    aspell-en aspell-bg tesseract-ocr tesseract-ocr-bul openssl webp git || exit 1

if [ -z "$PHP_VERSION" ]; then
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;') || exit 1
fi

phpenmod -v "$PHP_VERSION" imap || exit 1

# конфигурираме php 
if [ "$PHP_MODE" = "fpm" ]; then
    bash configure_php-fpm.ini.sh "/etc/php/${PHP_VERSION}/fpm/php.ini" || exit 1
else
    bash configure_php.ini.sh "/etc/php/${PHP_VERSION}/${PHP_SAPI}/php.ini" || exit 1
fi

# Часовата зона на PHP за CLI и за уеб сървъра (apache2 или fpm)
for PHP_INI in "/etc/php/${PHP_VERSION}/cli/php.ini" "/etc/php/${PHP_VERSION}/${PHP_SAPI}/php.ini"
do
    if [ ! -f "$PHP_INI" ]; then
        echo "PHP configuration file not found: $PHP_INI" >&2
        exit 1
    fi
    if grep -q '^;\?\s*date\.timezone\s*=' "$PHP_INI"; then
        sed -i "s|^;\?\s*date\.timezone\s*=.*|date.timezone = ${TIMEZONE}|" "$PHP_INI" || exit 1
    else
        echo "date.timezone = ${TIMEZONE}" >> "$PHP_INI" || exit 1
    fi
    echo "PHP date.timezone set to ${TIMEZONE} in $PHP_INI"
done

if [ "$PHP_MODE" = "fpm" ]; then
    # mod_php и другите MPM модули не могат да работят с mpm_event.
    for APACHE_MODULE in /etc/apache2/mods-enabled/php*.load \
        /etc/apache2/mods-enabled/mpm_prefork.load /etc/apache2/mods-enabled/mpm_worker.load
    do
        [ -e "$APACHE_MODULE" ] || continue
        APACHE_MODULE="${APACHE_MODULE##*/}"
        a2dismod "${APACHE_MODULE%.load}" || exit 1
    done
    a2enmod proxy_fcgi setenvif mpm_event || exit 1
    a2enconf "php${PHP_VERSION}-fpm" || exit 1
    systemctl enable "php${PHP_VERSION}-fpm" || exit 1
    service "php${PHP_VERSION}-fpm" restart || exit 1
fi

apache2ctl configtest || exit 1
service apache2 restart || exit 1

cd ${DIRECTORY}
git clone -b ${BRANCH} --single-branch https://github.com/bgerp/bgerp.git
cp bgerp/_docs/webroot . -R

cp bgerp/_docs/conf . -R
mv conf/myapp.cfg.php conf/bgerp.cfg.php

# Ако не е зададена - генерираме 6 символна парола за root потребителя на MySQL-a
[[  -z  ${DBROOTPASS}  ]] && DBROOTPASS=`openssl rand -base64 32` && DBROOTPASS=${DBROOTPASS//\//} && DBROOTPASS=${DBROOTPASS:3:6}
DBROOTPASS=${DBROOTPASS//\\/}
# сменяме паролата на MySQL-a
mysqladmin -uroot password ${DBROOTPASS}


# Ако не е зададена - генерираме 6 символна парола за потребителя
[[  -z  ${DBUSERPASS}  ]] && DBUSERPASS=`openssl rand -base64 32` && DBUSERPASS=${DBUSERPASS//\//} && DBUSERPASS=${DBUSERPASS:3:6} 
DBUSERPASS=${DBUSERPASS//\\/}

cat > /tmp/mysqldb.sql << EOF
CREATE DATABASE ${DBNAME};
CREATE USER ${DBUSERNAME}@localhost IDENTIFIED BY '${DBUSERPASS}';
GRANT ALL ON ${DBNAME}.* TO ${DBUSERNAME}@localhost;
GRANT RELOAD, LOCK TABLES ON *.*  TO ${DBUSERNAME}@localhost;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

mysql -uroot -p${DBROOTPASS} < /tmp/mysqldb.sql
rm /tmp/mysqldb.sql


# Подменяме името на приложението, потребителя и домейна по подразбиране
sed -i "s/DEFINE('EF_DB_NAME', EF_APP_NAME);/DEFINE('EF_DB_NAME', '${DBNAME}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_USER', EF_APP_NAME);/DEFINE('EF_DB_USER', '${DBUSERNAME}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('EF_DB_PASS', 'USER_PASSWORD_FOR_DB');/DEFINE('EF_DB_PASS', '${DBUSERPASS}');/g" conf/bgerp.cfg.php
sed -i "s/DEFINE('BGERP_VHOST', 'localhost');/DEFINE('BGERP_VHOST', '${VHOST}');/g" conf/bgerp.cfg.php

sed -i "s/DEFINE('EF_USERS_HASH_FACTOR', 0);/DEFINE('EF_USERS_HASH_FACTOR', 400);/g" conf/bgerp.cfg.php

# Задаваме солите със случайни стрингове
PASS_SALT=$( cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
sed -i "s/DEFINE('EF_USERS_PASS_SALT', '');/DEFINE('EF_USERS_PASS_SALT', '${PASS_SALT}');/g" conf/bgerp.cfg.php
EF_SALT=$( cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
sed -i "s/DEFINE('EF_SALT', '');/DEFINE('EF_SALT', '${EF_SALT}');/g" conf/bgerp.cfg.php

sed -i "s/DEFINE('BGERP_GIT_BRANCH', 'master');/DEFINE('BGERP_GIT_BRANCH', '${BRANCH}');/g" conf/bgerp.cfg.php

# Задаваме пътя до EF_ROOT и името на приложението
sed -i "s/# DEFINE('EF_ROOT_PATH', '\[#PATH_TO_FOLDER#\]');/DEFINE( 'EF_ROOT_PATH', '"${DIRECTORY//\//\\/}"');/g" webroot/index.cfg.php
sed -i "s/# DEFINE('EF_APP_NAME', 'bgerp');/DEFINE('EF_APP_NAME', 'bgerp');/g" webroot/index.cfg.php

# Инсталиране на допълнителен софтуер
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
apt install -y python3-setuptools-gettext
apt install -y timelimit

apt install -y inkscape
apt install -y tnef

apt install -y jpegoptim
apt install -y libjpeg-turbo-progs
apt install -y optipng
apt install -y pngquant
apt install -y wget
apt install -y curl

# Ubuntu 26.04 ограничава gs с AppArmor - разрешаваме му само четене на качените файлове на bgERP
if [ -f /etc/apparmor.d/gs ]; then
    GS_UPLOADS_RULE="file r \"$(realpath -m "${DIRECTORY}/uploads")/**\","
    mkdir -p /etc/apparmor.d/local
    grep -qsxF "$GS_UPLOADS_RULE" /etc/apparmor.d/local/gs || echo "$GS_UPLOADS_RULE" >> /etc/apparmor.d/local/gs
    apparmor_parser -r /etc/apparmor.d/gs || echo "Warning: AppArmor profile for gs is not reloaded" >&2
fi

bash "$START_DIR/FFMpegSetup.sh"

# Ако tifig е инсталиран успешно добавяме константа в bgerp.cfg.php файла
bash "$START_DIR/tifig_add.sh" -d=${DIRECTORY}
if [ $? -eq 0 ]; then
	FILE=${DIRECTORY}"/conf/bgerp.cfg.php"
	echo -e "\n\n/**\n * Път до tfig\n */\nDEFINE('TIFIG_PATH','${DIRECTORY}/tifig');" >> "$FILE"
	echo "tifig е описан успешно в $FILE."
else
    echo "Скриптът не се изпълни успешно."
fi

# добавяме bg aspell
bash "$START_DIR/aspell_add.sh"


chown www-data:www-data ${DIRECTORY} -R


crontab -l > cron.res
echo "* * * * * wget -q --spider --no-check-certificate https://"${VHOST}"/core_Cron/cron" >> cron.res
crontab cron.res
rm cron.res

# Създаване на файл, съдържащ информация с детайлите на инсталацията
echo "Installation information for bgERP" > ~/bgerp-install-"${DBNAME}".info
echo "==================================" >> ~/bgerp-install-"${DBNAME}".info
echo "DIRECTORY = "${DIRECTORY} >> ~/bgerp-install-"${DBNAME}".info
echo "VHOST = "${VHOST} >> ~/bgerp-install-"${DBNAME}".info
echo "BRANCH = "${BRANCH} >> ~/bgerp-install-"${DBNAME}".info
echo "DBNAME = "${DBNAME} >> ~/bgerp-install-"${DBNAME}".info
echo "DBROOTPASS = "${DBROOTPASS} >> ~/bgerp-install-"${DBNAME}".info
echo "DBUSERNAME = "${DBUSERNAME} >> ~/bgerp-install-"${DBNAME}".info
echo "DBUSERPASS = "${DBUSERPASS} >> ~/bgerp-install-"${DBNAME}".info
echo "MYSQLHOST = "${MYSQLHOST} >> ~/bgerp-install-"${DBNAME}".info
echo "PHP_MODE = "${PHP_MODE} >> ~/bgerp-install-"${DBNAME}".info

echo *****************************************************************
echo The bgERP system is installed on this server. To open it,   
echo "load in the browser http://"${VHOST}". The installation"      
echo parameters are saved in the file /root/bgerp-install.info   
echo *****************************************************************

cat ~/bgerp-install-"${DBNAME}".info
