#!/bin/bash

if [ "$VERSION_ID" = "24.04" ]; then
		# Ubuntu 24.04
		export PHP_INI_PATH=/etc/php/7.4/apache2/php.ini
	
	elif [ "$VERSION_ID" = "26.04" ]; then
		export PHP_INI_PATH=/etc/php/8.2/apache2/php.ini
fi


	

upload_max_filesize=128M
post_max_size=128M
max_execution_time=60
memory_limit=1024M

for key in upload_max_filesize post_max_size max_execution_time memory_limit
do
 sed -i "s/^\($key\).*/\1 $(eval echo = \${$key})/" $PHP_INI_PATH
done