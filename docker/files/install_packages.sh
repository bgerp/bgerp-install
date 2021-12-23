#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update  -yq
apt-get install -yq --no-install-recommends apt-utils
apt-get dist-upgrade -yq
apt-get install -yq --no-install-recommends locales
locale-gen en_US.UTF-8 en_GB.UTF-8 de_DE.UTF-8 es_ES.UTF-8 fr_FR.UTF-8 it_IT.UTF-8 bg_BG.UTF-8
apt-get install -yq --no-install-recommends tzdata
apt-get install -yq --no-install-recommends git curl zlib1g-dev unzip openssh-client ca-certificates
apt-get install -yq --no-install-recommends software-properties-common
add-apt-repository ppa:ondrej/php -y
apt-get update  -yq
apt-get install -yq --no-install-recommends \
			php7.3-cli \
			php7.3-pdo php7.3-mysql php7.3-mysqli php7.3-sqlite3 php7.3-pgsql php7.3-mongodb \
			php7.3-curl php7.3-zip php7.3-bcmath php7.3-bz2 php7.3-gd php7.3-intl php7.3-imagick php7.3-mbstring \
			php7.3-xml  php7.3-json php7.3-xsl php7.3-dom \
			php7.3-ldap php7.3-soap php7.3-xmlrpc php7.3-xmlwriter php7.3-phar \
			php7.3-imap php7.3-bz2 \
			php7.3-ctype php7.3-iconv php7.3-fileinfo php7.3-tokenizer \
			php7.3-apcu php7.3-memcached php7.3-redis php7.3-opcache \
			php7.3-amqp php7.3-igbinary php7.3-msgpack php7.3-pspell \
			php7.3-xdebug \
			apache2 libapache2-mod-php7.3 aspell-en aspell-bg tesseract-ocr tesseract-ocr-bul openssl \
			wkhtmltopdf xvfb ghostscript imagemagick zbar-tools xpdf-utils p7zip-full p7zip-rar default-jre unoconv timelimit inkscape tnef jpegoptim libjpeg-turbo-progs optipng pngquant wget \
			webp
a2dismod mpm_event
a2enmod php7.3 actions rewrite headers expires deflate env filter mime setenvif remoteip mpm_prefork
