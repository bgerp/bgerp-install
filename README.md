# bgerp-install
Bash скрипт за инсталиране на [bgERP](https://bgerp.com) 

---

##### Изисквания
- чиста инсталация на Ubuntu server 24.04 или 26.04


##### Инсталация
- пакета се сваля с командата: `git clone https://github.com/bgerp/bgerp-install.git`<br>
    или `wget https://github.com/bgerp/bgerp-install/archive/master.zip && unzip master.zip`
- влиза се в директорията `bgerp-install`
- стартира се `install_bgERP.sh` като потребител `root` или със `sudo`
Възможни са следните параметри за подаване:
    - `-h, --help`                 показва помощна информация
    - `-d, --directory`            задава директорията за инсталиране на bgERP /`EF_ROOT_PATH`/
    - `-u, --url`                  указва виртуален хост за apache
    - `-b, --branch`               бранч на кода на bgERP /`DC1`, `DC2`, `master`/
    - `-n, --dbname`               име на базата данни в MySQL сървъра
    - `-p, --dbrootpass`           парола за MySQL root потребителя /създава се произволна, ако не се зададе/
    - `-s, --dbusername`           потребител за базата
    - `-a, --dbuserpass`           парола за потребителя за базата /създава се произволна, ако не се зададе/
    - `-f, --php-mode`             режим на PHP: `apache` (по подразбиране, mod_php) или `fpm` (PHP-FPM)

##### Примерно стартиране:
`sudo ./install_bgERP.sh -d=/var/www -u=bgerp.local -b=DC2 -s=bgerpuser -n=bgerpbase`

За инсталация с PHP-FPM добавете `--php-mode=fpm` (или `-f=fpm`):

`sudo ./install_bgERP.sh -d=/var/www -u=bgerp.local -b=DC2 -s=bgerpuser -n=bgerpbase --php-mode=fpm`

Режимът `fpm` инсталира PHP-FPM вместо mod_php, активира Apache `proxy_fcgi`,
`setenvif` и `mpm_event` и настройва `/etc/php/<версия>/fpm/php.ini`.
Версията на PHP остава 7.4 за Ubuntu 24.04 и 8.2 за Ubuntu 26.04.

резултатен файл с параметрите на инсталацията и паролите се записва в `/root/bgerp-install.info`


##### TODO:
- да се имплементират следните параметри:
    - `-m, --mysqlhost`            адрес на съществуващ MySQL сървър
    - `-c, --config`               конфигурационен файл от друга инсталация
