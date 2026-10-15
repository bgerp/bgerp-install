#!/bin/bash

PHP_INI_PATH="${1:-}"

if [ -z "$PHP_INI_PATH" ]; then
    . /etc/os-release

    if [ "$VERSION_ID" = "24.04" ]; then
        PHP_INI_PATH=/etc/php/7.4/apache2/php.ini
    elif [ "$VERSION_ID" = "26.04" ]; then
        PHP_INI_PATH=/etc/php/8.2/apache2/php.ini
    fi
fi

if [ ! -f "$PHP_INI_PATH" ]; then
    echo "PHP configuration file not found: $PHP_INI_PATH" >&2
    exit 1
fi

upload_max_filesize=128M
post_max_size=128M
max_execution_time=60
memory_limit=1024M

for key in upload_max_filesize post_max_size max_execution_time memory_limit
do
 sed -i "s/^\($key\).*/\1 = ${!key}/" "$PHP_INI_PATH" || exit 1
done
