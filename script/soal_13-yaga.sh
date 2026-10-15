#!/bin/sh

apt-get update
apt-get install -y mariadb-server mariadb-client

service mariadb start
service mariadb status

nano /etc/mysql/mariadb.conf.d/50-server.cnf

CONF=/etc/mysql/mariadb.conf.d/50-server.cnf

cp "$CONF" "$CONF.bak"

sed -i 's/^[[:space:]]*bind-address[[:space:]]*=.*/bind-address = 0.0.0.0/' "$CONF"

service mariadb restart

grep -n 'bind-address' "$CONF"

netstat -tlpn | grep 3306
ss -tlpn | grep 3306

mariadb -u root

# Di MariaDB
> CREATE DATABASE db_shibuya_k35;

> CREATE USER 'k35'@'%' IDENTIFIED BY 'passwordk35';
> GRANT ALL PRIVILEGES ON db_shibuya_k35.* TO 'k35'@'%';
> FLUSH PRIVILEGES;

> USE db_shibuya_k35;

-- Tabel untuk mencatat riwayat akses request dari load balancer
> CREATE TABLE request_logs (
>    id INT AUTO_INCREMENT PRIMARY KEY,
>    worker_name VARCHAR(50) NOT NULL,
>    client_ip VARCHAR(50) NOT NULL,
>    proxy_ip VARCHAR(50) NOT NULL,
>    user_agent TEXT,
>    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
> );

> EXIT;

mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql
chmod 750 /var/log/mysql

service mariadb restart

nano /etc/mysql/mariadb.conf.d/50-server.cnf
# Tambahkan:
[mysqld]
server-id       = 1
log_bin         = /var/log/mysql/mariadb-bin.log
binlog_do_db    = db_shibuya_k35

service mariadb restart

mariadb -u root

> -- Buat user untuk akses slave
> CREATE USER 'replica_user'@'%' IDENTIFIED BY 'passwordk35';
> GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'%';
> FLUSH PRIVILEGES;

> -- Lihat status file dan posisi binary log saat ini
> SHOW MASTER STATUS;
