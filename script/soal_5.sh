cat > /root/soal_5.sh <<'SCRIPT'
#!/bin/bash
# Soal 5 - Short lease & long lease Network 3 (sudah mencakup konfigurasi Soal 4)
cat > /etc/dhcp/dhcpd.conf <<'CONF'
authoritative;

subnet 10.81.4.0 netmask 255.255.255.0 {
}

# ===== Class Network 2 =====
class "pool1" {
    match if substring(hardware, 1, 6) = 02:42:4f:be:32:00
          or substring(hardware, 1, 6) = 02:42:08:2d:e1:00;
}

class "pool2" {
    match if substring(hardware, 1, 6) = 02:42:13:ec:82:00
          or substring(hardware, 1, 6) = 02:42:94:57:ff:00;
}

# ===== Class Network 3 =====
class "short" {
    match if substring(hardware, 1, 6) = 02:42:31:1d:d6:00
          or substring(hardware, 1, 6) = 02:42:7c:8c:00:00;
    default-lease-time 1800;
    max-lease-time 1800;
}

class "long" {
    match if substring(hardware, 1, 6) = 02:42:81:38:66:00;
    default-lease-time 43200;
    max-lease-time 43200;
}

subnet 10.81.2.0 netmask 255.255.255.0 {
    option routers 10.81.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.81.2.255;
    option domain-name-servers 192.168.122.1;
    default-lease-time 600;
    max-lease-time 3600;

    pool {
        range 10.81.2.10 10.81.2.35;
        allow members of "pool1";
    }
    pool {
        range 10.81.2.70 10.81.2.95;
        allow members of "pool2";
    }
}

subnet 10.81.3.0 netmask 255.255.255.0 {
    option routers 10.81.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.81.3.255;
    option domain-name-servers 10.81.1.2, 10.81.1.3;
    option domain-search "K35.com";

    pool {
        range 10.81.3.10 10.81.3.89;
        allow members of "short";
    }
    pool {
        range 10.81.3.100 10.81.3.199;
        allow members of "long";
    }
}
CONF

echo "===== VALIDASI ====="
dhcpd -t -cf /etc/dhcp/dhcpd.conf || { echo "Konfigurasi ERROR"; exit 1; }
service isc-dhcp-server stop >/dev/null 2>&1
: > /var/lib/dhcp/dhcpd.leases
service isc-dhcp-server start
sleep 1
ps aux | grep [d]hcpd
echo "Sekarang jalankan client.sh di ino, kusakabe, miwa."
echo "Bukti lease: grep -E '^lease|starts|ends|hardware' /var/lib/dhcp/dhcpd.leases"
SCRIPT
chmod +x /root/soal_5.sh