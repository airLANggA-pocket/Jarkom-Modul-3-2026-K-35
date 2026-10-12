cat > /root/soal_2.sh <<'SCRIPT'
#!/bin/bash
# Soal 2 - isc-dhcp-server di tengen (10.81.4.10)
which dhcpd >/dev/null 2>&1 || (apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server)

cat > /etc/default/isc-dhcp-server <<'CONF'
INTERFACESv4="eth0"
INTERFACESv6=""
CONF

cat > /etc/dhcp/dhcpd.conf <<'CONF'
authoritative;

# Network 4 - subnet lokal, tanpa pool dinamis
subnet 10.81.4.0 netmask 255.255.255.0 {
}

# Network 2 - Divisi A
subnet 10.81.2.0 netmask 255.255.255.0 {
    range 10.81.2.100 10.81.2.200;
    option routers 10.81.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.81.2.255;
    option domain-name-servers 192.168.122.1;
    default-lease-time 600;
    max-lease-time 3600;
}

# Network 3 - Divisi B
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
service isc-dhcp-server status
ps aux | grep [d]hcpd
ss -ulpn | grep :67
SCRIPT
chmod +x /root/soal_2.sh