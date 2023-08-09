#!/bin/bash
export PHP_INI_PATH=/etc/php/7.4/apache2/php.ini

upload_max_filesize=128M
post_max_size=128M
max_execution_time=60
memory_limit=1024M

for key in upload_max_filesize post_max_size max_execution_time memory_limit
do
 sed -i "s/^\($key\).*/\1 $(eval echo = \${$key})/" $PHP_INI_PATH
done