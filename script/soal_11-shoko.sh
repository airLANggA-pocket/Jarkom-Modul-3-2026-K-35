#!/bin/sh

apt-get update
apt-get install bind9 -y

ln -s /etc/init.d/named /etc/init.d/bind9

cat <<'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k35.com" {
    type slave;
    masters { 10.81.1.2; };
    file "/var/cache/bind/jujutsu.k35.com";
};
EOF

named-checkconf &&
service bind9 restart