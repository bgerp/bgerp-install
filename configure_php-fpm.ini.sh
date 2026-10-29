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

# Пулът на FPM е до php.ini, ако не е зададен изрично
FPM_POOL_PATH="${2:-$(dirname "$PHP_INI_PATH")/pool.d/www.conf}"

for CONF_PATH in "$PHP_INI_PATH" "$FPM_POOL_PATH"
do
    if [ ! -f "$CONF_PATH" ]; then
        echo "PHP configuration file not found: $CONF_PATH" >&2
        exit 1
    fi
done

# Настройките на bgERP, които се различават от php.ini-production
PHP_SETTINGS=(
    "max_execution_time=60"
    "memory_limit=256M"
    "post_max_size=128M"
    "upload_max_filesize=128M"
    "date.timezone=Europe/Sofia"
    "session.upload_progress.enabled=Off"
)

# Настройките на bgERP, които се различават от pool.d/www.conf по подразбиране
POOL_SETTINGS=(
    "pm.max_children=25"
    "pm.start_servers=8"
    "pm.min_spare_servers=6"
    "pm.max_spare_servers=12"
    "pm.max_requests=500"
)

# Заменяме реда с настройката (и закоментирания) или я добавяме в края
set_option() {
    local file="$1" key="$2" value="$3"
    local re="${key//./\\.}"

    if grep -q "^;\?\s*${re}\s*=" "$file"; then
        sed -i "s|^;\?\s*${re}\s*=.*|${key} = ${value}|" "$file"
    else
        echo "${key} = ${value}" >> "$file"
    fi
}

for setting in "${PHP_SETTINGS[@]}"
do
    set_option "$PHP_INI_PATH" "${setting%%=*}" "${setting#*=}" || exit 1
done

for setting in "${POOL_SETTINGS[@]}"
do
    set_option "$FPM_POOL_PATH" "${setting%%=*}" "${setting#*=}" || exit 1
done
