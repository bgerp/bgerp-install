#!/bin/bash

_a='<Directory '$DIRECTORY'/'$PUBLIC_DIR_NAME'/>'
_a+='\n <IfModule mod_rewrite.c>\n RewriteEngine On \nRewriteCond %{REQUEST_FILENAME} !-d \n RewriteCond %{REQUEST_FILENAME} !-f \n RewriteRule ^(.*)$ index.php?virtual_url=$1 [QSA,L]'
_a+='\n </IfModule>'
_a+='\n <IfModule mod_deflate.c>'
_a+='\n     AddOutputFilter DEFLATE php'
_a+='\n </IfModule>'
_a+='\n     Options Indexes FollowSymLinks \nAllowOverride None \nRequire all granted'
_a+='\n </Directory>'
_a+='\n <IfModule mod_deflate.c>'
_a+='\n     AddOutputFilter DEFLATE php'
_a+='\n </IfModule>'
_a+='\n     Options Indexes FollowSymLinks \nAllowOverride None \nRequire all granted'
_a+='\n </Directory>'

_a+='<Directory '$DIRECTORY'/'$PUBLIC_DIR_NAME'/sbf/bgerp/>'
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

_a="${_a//\//\\/}"

echo ${_a}







exit;

DBROOTPASS=21212
DBNAME=bgerp_copy3
DBUSERNAME=bgerp3

RES=`mysql -uroot -p${DBROOTPASS} --skip-column-names -e"SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${DBUSERNAME}')"`
echo ${RES}
exit 1
if [ ${RES} = 1 ]; then
	echo "DBUSERNAME exists! -- ${DBUSERNAME}. Use other DBUSERNAME name. Installation stopped."
   	exit 0
fi 

exit 0


if [ ! -f `which mysql` ] ; then
    echo "Nqma MYSQL" 
    else
    # check permisions
    RES=`mysql -uroot -p${DBROOTPASS} -e"show databases" | grep -o ${DBNAME} 2>&1`
    if [ "${DBNAME}" = "${RES}" ]; then
    	echo "DBName exists! -- ${DBNAME} -- ${RES}"
    fi    
fi