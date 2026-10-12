cat > /root/soal_4.sh <<'SCRIPT'
#!/bin/bash
# Soal 4 - Dua pool Network 2 dengan DHCP class (MAC)
cat > /etc/dhcp/dhcpd.conf <<'CONF'
authoritative;

subnet 10.81.4.0 netmask 255.255.255.0 {
}

class "pool1" {
    match if substring(hardware, 1, 6) = 02:42:4f:be:32:00
          or substring(hardware, 1, 6) = 02:42:08:2d:e1:00;
}

class "pool2" {
    match if substring(hardware, 1, 6) = 02:42:13:ec:82:00
          or substring(hardware, 1, 6) = 02:42:94:57:ff:00;
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
    range 10.81.3.100 10.81.3.200;
    option routers 10.81.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.81.3.255;
    option domain-name-servers 192.168.122.1;
    default-lease-time 600;
    max-lease-time 3600;
}
CONF

echo "===== VALIDASI ====="
dhcpd -t -cf /etc/dhcp/dhcpd.conf || { echo "Konfigurasi ERROR"; exit 1; }
service isc-dhcp-server stop >/dev/null 2>&1
: > /var/lib/dhcp/dhcpd.leases
service isc-dhcp-server start
sleep 1
ps aux | grep [d]hcpd
echo "Sekarang jalankan client.sh di itadori, fushiguro, zenin, okkotsu."
echo "Bukti lease: grep -E '^lease|hardware' /var/lib/dhcp/dhcpd.leases"
SCRIPT
chmod +x /root/soal_4.sh