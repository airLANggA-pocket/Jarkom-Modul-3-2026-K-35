cat > /root/soal_3.sh <<'SCRIPT'
#!/bin/bash
# Soal 3 - DHCP Relay di jichi menuju tengen (10.81.4.10)
which dhcrelay >/dev/null 2>&1 || (apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay)

cat > /etc/default/isc-dhcp-relay <<'CONF'
SERVERS="10.81.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
CONF

sysctl -w net.ipv4.ip_forward=1
service isc-dhcp-relay restart
sleep 1

echo "===== BUKTI ====="
cat /etc/default/isc-dhcp-relay
service isc-dhcp-relay status
ps aux | grep [d]hcrelay
sysctl net.ipv4.ip_forward
ping -c 2 10.81.4.10
SCRIPT
chmod +x /root/soal_3.sh