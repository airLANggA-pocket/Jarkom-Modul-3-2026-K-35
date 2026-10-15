#!/bin/bash

cat <<'EOF' > /etc/bind/k35/jujutsu.k35.com
$TTL 604800
@       IN  SOA utahime.k35.com. admin.k35.com. (
        2026101202 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800     ; Negative Cache TTL
)

@       IN      NS      utahime.k35.com.
@       IN      NS      shoko.k35.com.

@       IN      A       10.81.1.4

www     IN      CNAME   jujutsu.k35.com.
EOF

cat <<'EOF' > /etc/bind/named.conf.options
options {
        directory "/var/cache/bind";
        forwarders {
                192.168.122.1;
        };
        allow-query { any; };
        auth-nxdomain no;
        listen-on { any; };
        listen-on-v6 { any; };
};
EOF

service bind9 restart

cat <<'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k35.com" {
    type master;
    notify yes;
    also-notify { 10.81.1.3; };
    allow-transfer { 10.81.1.3; };
    file "/etc/bind/k35/jujutsu.k35.com";
};

zone "1.81.10.in-addr.arpa" {
        type master;
        notify yes;
        also-notify { 10.81.1.3; };
        allow-transfer { 10.81.1.3; };
        file "/etc/bind/k35/1.81.10.in-addr.arpa";
};
EOF

cat <<'EOF' > /etc/bind/k35/1.81.10.in-addr.arpa
$TTL    604800          ; Waktu cache default (detik)
@       IN      SOA     utahime.k35.com. admin.k35.com. (
                        2026101202 ; Serial (format YYYYMMDDXX)
                        604800     ; Refresh (1 minggu)
                        86400      ; Retry (1 hari)
                        2419200    ; Expire (4 minggu)
                        604800 )   ; Negative Cache TTL
;

@       IN      NS      utahime.k35.com.
@       IN      NS      shoko.k35.com.

4       IN      PTR     jujutsu.k35.com.
EOF

named-checkconf
named-checkzone jujutsu.k35.com /etc/bind/k35/jujutsu.k35.com
named-checkzone 1.81.10.in-addr.arpa /etc/bind/k35/1.81.10.in-addr.arpa

service bind9 restart
service bind9 status
