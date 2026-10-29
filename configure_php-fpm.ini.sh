#!/bin/bash

PHP_INI_PATH="${1:-}"

if [ -z "$PHP_INI_PATH" ]; then
    . /etc/os-release

    if [ "$VERSION_ID" = "24.04" ]; then
        PHP_INI_PATH=/etc/php/7.4/fpm/php.ini
    elif [ "$VERSION_ID" = "26.04" ]; then
        PHP_INI_PATH=/etc/php/8.2/fpm/php.ini
    fi
fi

if [ ! -f "$PHP_INI_PATH" ]; then
    echo "PHP configuration file not found: $PHP_INI_PATH" >&2
    exit 1
fi

# Настройките на bgERP, които се различават от php.ini-production
SETTINGS=(
    "max_execution_time=60"
    "memory_limit=1024M"
    "post_max_size=128M"
    "upload_max_filesize=128M"
    "date.timezone=Europe/Sofia"
    "session.upload_progress.enabled=Off"
)

for setting in "${SETTINGS[@]}"
do
    key="${setting%%=*}"
    value="${setting#*=}"
    re="${key//./\\.}"

    # Заменяме реда с настройката (и закоментирания) или я добавяме в края
    if grep -q "^;\?\s*${re}\s*=" "$PHP_INI_PATH"; then
        sed -i "s|^;\?\s*${re}\s*=.*|${key} = ${value}|" "$PHP_INI_PATH" || exit 1
    else
        echo "${key} = ${value}" >> "$PHP_INI_PATH" || exit 1
    fi
done
