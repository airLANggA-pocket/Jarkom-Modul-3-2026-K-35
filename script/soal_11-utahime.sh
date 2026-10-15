#!/bin/sh

apt-get update
apt-get install bind9 -y

ln -s /etc/init.d/named /etc/init.d/bind9

mkdir -p /etc/bind/k35

cat <<'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k35.com" {
    type master;
    notify yes;
    also-notify { 10.81.1.3; };
    allow-transfer { 10.81.1.3; };
    file "/etc/bind/k35/jujutsu.k35.com";
};
EOF

cat <<'EOF' > /etc/bind/k35/jujutsu.k35.com
$TTL 604800

@   IN  SOA utahime.k35.com. admin.k35.com. (
        2026101201 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800     ; Negative Cache TTL
)

@   IN  NS  utahime.k35.com.
@   IN  NS  shoko.k35.com.
EOF

named-checkconf &&
named-checkzone jujutsu.k35.com /etc/bind/k35/jujutsu.k35.com &&
service bind9 restart

ping -c 5 jujutsu.k35.com