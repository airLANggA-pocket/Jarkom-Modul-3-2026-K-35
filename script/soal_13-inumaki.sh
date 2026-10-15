#!/bin/bash

apt-get update -y
apt-get install -y mariadb-server mariadb-client

service mariadb start
service mariadb status

nano /etc/mysql/mariadb.conf.d/50-server.cnf

# Tambahkan
# [mysqld]
# server-id       = 2

service mariadb restart

mariadb -u root

# Perhatikan Log File dan Log Pos

# Di MariaDB
> -- Arahkan Slave ke data Master (sesuaikan IP dan parameter SHOW MASTER STATUS)
> CHANGE MASTER TO
>    MASTER_HOST='10.81.4.9',
>   MASTER_USER='replica_user',
>    MASTER_PASSWORD='password123',
>    MASTER_LOG_FILE='mariadb-bin.000001',
>    MASTER_LOG_POS=829;

> -- Jalankan proses sinkronisasi slave
> START SLAVE;

> SHOW SLAVE STATUS;
