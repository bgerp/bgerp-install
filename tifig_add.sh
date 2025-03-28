#!/bin/bash

ROOT_UID=0
NOTROOT=87

# Проверка права
if [ $UID -ne $ROOT_UID ]
    then echo “You must be root to run this script.” 
    exit $NOTROOT
fi

display_help() {
    echo "Usage: $0 [option= ...] " >&2
    echo
    echo "   -h, --help                 Show this help"
    echo "   -d, --directory            dirertory to install tifig"
    echo

    exit 1
}

for i in "$@"
do
case $i in
    -d=*|--directory=*)
    DIRECTORY="${i#*=}"
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

# Създава целева директория ако я няма
if [ ! -d "$DIRECTORY" ] 
then
    mkdir -p -v "$DIRECTORY" 
else
    if [ "$(ls -A "$DIRECTORY")" ]; then
    	 echo $DIRECTORY" вече съществува"
    fi    
fi

# Инсталиране на tifig
TARGET_DIR="${DIRECTORY}/tifig"
mkdir -p "$TARGET_DIR" || echo "Грешка: Не може да се създаде директория $TARGET_DIR."
FILE_URL="https://github.com/monostream/tifig/releases/download/0.2.2/tifig-static-0.2.2.tar.gz"
# Създаваме временна директория
TMP_DIR=$(mktemp -d)
ARCHIVE="$TMP_DIR/tifig-static-0.2.2.tar.gz"
echo "Изтеглям файла от $FILE_URL..."
if ! curl -L "$FILE_URL" -o "$ARCHIVE"; then
  echo "Грешка: Неуспешно изтегляне на файла от $FILE_URL."
  exit -1;
else
  echo "Файлът беше изтеглен успешно."
fi
echo "Опитвам се да разархивирам файла..."
if ! tar -xzf "$ARCHIVE" -C "$TMP_DIR"; then
  echo "Грешка: Неуспешно разархивиране на $ARCHIVE."
  exit -1;
else
  echo "Файлът беше разархивиран успешно."
fi
# Търсим изпълнимия файл "tifig" в разархивираните данни
TIFIG_BINARY=$(find "$TMP_DIR" -type f -name "tifig" | head -n 1)
if [ -z "$TIFIG_BINARY" ]; then
  echo "Грешка: Не е намерен изпълнимият файл 'tifig' в разархивираните данни."
  exit -1;
else
  echo "Намерен е изпълнимият файл: $TIFIG_BINARY."
  if cp "$TIFIG_BINARY" "$TARGET_DIR/"; then
    chmod +x "$TARGET_DIR/tifig"
    echo "'tifig' беше успешно копиран в $TARGET_DIR."
  else
    echo "Грешка: Не може да се копира 'tifig' в $TARGET_DIR."
    exit -1;
  fi
fi

# Изчистваме временната директория
rm -rf "$TMP_DIR"

exit 0
