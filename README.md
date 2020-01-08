# bgerp-install
Bash скрипт за инсталиране на [bgERP](https://bgerp.com) 

---

##### Изисквания
- чиста инсталация на Ubuntu server 16.04 или 18.04
- не работи на Ubuntu 18.04.1 но работи на Ubuntu 18.04


##### Инсталация
- пакета се сваля с командата: `git clone https://github.com/bgerp/bgerp-install.git`
- влиза се в директорията `bgerp-install`
- стартира се `install_bgERP_php7.sh` като потребител `root` или със `sudo`
Възможни са следните параметри за подаване:
    - -h, --help                 показва помощна информация
    - -d, --directory            задава директорията за инсталиране на bgERP /`EF_ROOT_PATH`/
    - -u, --url                  указва виртуален хост за apache
    - -b, --branch               бранч на кода на bgERP /`DC1`, `DC2`, `master`/
    - -n, --dbname               име на базата данни в MySQL сървъра
    - -p, --dbrootpass           парола за MySQL root потребителя
    - -s, --dbusername           потребител за базата
    - -a, --dbuserpass           парола за потребителя за базата

##### TODO

    - -m, --mysqlhost            адрес на MySQL сървъра
    - -c, --config               конфигурационен файл от друга инсталация
