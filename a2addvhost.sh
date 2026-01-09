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
    echo "   -s, --ssl                  Add ssl host yes/no"
    echo

    exit 1
}


VHOST_AVAILABLE=/etc/apache2/sites-available/
PUBLIC_DIR_NAME=webroot

# set defaults
DIRECTORY=/var/www
VHOST=localhost
SSL=no

for i in "$@"
do
case $i in
    -d=*|--directory=*)
    DIRECTORY="${i#*=}"
    ;;
    -u=*|--url=*)
    VHOST="${i#*=}"
    ;;
    -s=*|--ssl=*)
    SSL="${i#*=}"
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
if [ ! -d "$DIRECTORY"/"$PUBLIC_DIR_NAME" ] 
then
    mkdir -p -v $DIRECTORY"/"$PUBLIC_DIR_NAME 
else
    if [ "$(ls -A $DIRECTORY)" ]; then
    	 echo $DIRECTORY"/"$PUBLIC_DIR_NAME " exists"
         exit -1;
    fi    
fi


# 2. Make a copy of the new host configuration file
cp $VHOST_AVAILABLE"000-default.conf" $VHOST_AVAILABLE$VHOST".conf"
if [ $SSL == "yes" ]; then
	cp $VHOST_AVAILABLE"default-ssl.conf" $VHOST_AVAILABLE$VHOST"-ssl.conf"
fi

# Extract default host path
default_path=`sed -n 's/.*DocumentRoot\s\(.*\)\s*/\1/p' $VHOST_AVAILABLE$VHOST".conf"`

# Server name
_s="ServerName\\s\\+.\\+"
_r="ServerName $VHOST"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST".conf"
if [ $SSL == "yes" ]; then
	sed -i "/ServerAdmin/a ${_r}/g" $VHOST_AVAILABLE$VHOST"-ssl.conf"
	sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST"-ssl.conf"
fi

_s="#ServerName $VHOST"
_r="ServerName $VHOST"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST".conf"
if [ $SSL == "yes" ]; then
	sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST"-ssl.conf"
fi

# Write new DocumentRoot
_s=$default_path
_r=$DIRECTORY"/"$PUBLIC_DIR_NAME
_s="${_s//\//\\/}"
_r="${_r//\//\\/}"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST".conf"
if [ $SSL == "yes" ]; then
	sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST"-ssl.conf"
fi

# Set apache DocumentRoot permissions
_s=$DIRECTORY"/"$PUBLIC_DIR_NAME
_a=' <Directory '$DIRECTORY'/'$PUBLIC_DIR_NAME'/>'
_a+='\n 	AllowMethods GET POST HEAD'
_a+='\n     <IfModule mod_rewrite.c>'
_a+='\n     	RewriteEngine On'
_a+='\n     	RewriteCond %{REQUEST_FILENAME} !-d'
_a+='\n     	RewriteCond %{REQUEST_FILENAME} !-f'
_a+='\n     	RewriteRule ^(.*)$ index.php?virtual_url=$1 [QSA,L]'

# За избягване на възможността за 2 сесии
WWW="${VHOST:0:3}"
WWW=$(echo $WWW | tr '[:upper:]' '[:lower:]')
# Ако $VHOST започва с www добавяме правило - ако няма www - добавяме www
if [ $WWW == "www" ]; then
	_a+='\n     	RewriteCond %{HTTPS} off'
	_a+='\n     	RewriteCond %{HTTP_HOST} !^www\.(.*)$ [NC]'
	_a+='\n     	RewriteRule ^(.*)$ http://www.%{HTTP_HOST}/$1 [R=301,L]'

	_a+='\n     	RewriteCond %{HTTPS} on'
	_a+='\n     	RewriteCond %{HTTP_HOST} !^www\.(.*)$ [NC]'
	_a+='\n     	RewriteRule ^(.*)$ https://www.%{HTTP_HOST}/$1 [R=301,L]'
fi

# Ако $VHOST не започва с www добавяме правило - ако има www - махаме www
if [ $WWW != "www" ]; then
	_a+='\n     	RewriteCond %{HTTPS} off'
	_a+='\n     	RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]'
	_a+='\n     	RewriteRule ^(.*)$ http://%1/$1 [R=301,L]'

	_a+='\n     	RewriteCond %{HTTPS} on'
	_a+='\n     	RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]'
	_a+='\n     	RewriteRule ^(.*)$ https://%1/$1 [R=301,L]'
fi
_a+='\n 	</IfModule>'
_a+='\n 	<IfModule mod_deflate.c>'
_a+='\n     	AddOutputFilter DEFLATE php'
_a+='\n 	</IfModule>'
_a+='\n     	Options Indexes FollowSymLinks \nAllowOverride None \nRequire all granted'
_a+='\n 	</Directory>'

_a+='\n <Directory '$DIRECTORY'/'$PUBLIC_DIR_NAME'/sbf/bgerp/>'
_a+='\n <IfModule mod_headers.c>'
_a+='\n     <FilesMatch "\.(pdf|doc|docs|html|htm|txt|rtf|xls)$">' 
_a+='\n         Header set X-Robots-Tag "noindex, nofollow"'
_a+='\n      </FilesMatch>'
_a+='\n     Header set Cache-control "max-age=290304000, public"'
_a+='\n     Header set Expires "Tue, 20 Jan 2037 04:20:42 GMT"'
_a+='\n     Header unset ETag'
_a+='\n     FileETag None'
_a+='\n </IfModule>'
_a+='\n <FilesMatch "\.(htaccess|htpasswd)$">'
_a+='\n 	Order Allow,Deny'
_a+='\n  	Deny from all'
_a+='\n </FilesMatch>'
_a+='\n Options FollowSymLinks'
_a+='\n AllowOverride None'
_a+='\n Require all granted'
_a+='\n AddType text/plain .php'
_a+='\n AddType video/ogg .ogv'
_a+='\n AddType video/mp4 .mp4'
_a+='\n AddType video/webm .webm'
_a+='\n AddType video/x-flv .flv'
_a+='\n AddType audio/wav .wav'
_a+='\n AddType audio/mpeg .mp3'
_a+='\n AddType audio/ogg .oga'
_a+='\n AddType audio/ogg .ogg'
_a+='\n AddType audio/aac .aac'
_a+='\n </Directory>'

_a+='\n # EF_DOWNLOAD_DIR'
_a+='\n <Directory '$DIRECTORY'/'$PUBLIC_DIR_NAME'/sbf/bgerp/_dl_/>'
_a+='\n <IfModule mod_headers.c>'
_a+='\n 	Header set X-Robots-Tag "noindex"'
_a+='\n 	Header set Content-Disposition attachment'
_a+='\n </IfModule>'
_a+='\n <FilesMatch "(?<!\.ogv|\.mp4|\.webm|\.flv|\.wav|\.mp3|\.oga|\.ogg|\.aac)$">'
_a+='\n 	ForceType application/octet-stream'
_a+='\n </FilesMatch>'
_a+='\n Options FollowSymLinks'
_a+='\n AllowOverride None'
_a+='\n Require all granted'
_a+='\n AddType text/plain .php'
_a+='\n AddType video/ogg .ogv'
_a+='\n AddType video/mp4 .mp4'
_a+='\n AddType video/webm .webm'
_a+='\n AddType video/x-flv .flv'
_a+='\n AddType audio/wav .wav'
_a+='\n AddType audio/mpeg .mp3'
_a+='\n AddType audio/ogg .oga'
_a+='\n AddType audio/ogg .ogg'
_a+='\n AddType audio/aac .aac'
_a+='\n </Directory>'

_s="${_s//\//\\/}"
_a="${_a//\//\\/}"
#echo ${_s}
#echo ${_a}
#echo "/\\${_s}/a ${_a}" 

sed -i "/${_s}/a ${_a}" $VHOST_AVAILABLE$VHOST".conf"
if [ $SSL == "yes" ]; then
	sed -i "/${_s}/a ${_a}" $VHOST_AVAILABLE$VHOST"-ssl.conf"
fi

# Change error.log path
_s="error.log"
_r="$VHOST-error.log"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST".conf"
if [ $SSL == "yes" ]; then
	sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST"-ssl.conf"
fi

# Change access.log path
_s="access.log"
_r="$VHOST-access.log"
sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST".conf"
if [ $SSL == "yes" ]; then
	sed -i "s/${_s}/${_r}/g" $VHOST_AVAILABLE$VHOST"-ssl.conf"
fi

# Change webroot path
chown -R www-data:www-data $DIRECTORY

# 4. Enable new host
a2ensite $VHOST
a2ensite $VHOST"-ssl"
a2dissite 000-default

# 5. Update host file
echo -e "127.0.1.1\t$VHOST" >> /etc/hosts

# 6. Restart apache
/etc/init.d/apache2 reload

echo "Host $VHOST created."

exit 0;

END

