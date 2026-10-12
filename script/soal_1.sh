cat > /root/soal_1.sh <<'SCRIPT'
#!/bin/bash
# Soal 1 - Konektivitas dasar. Isi sama di semua node server.
NAME=$(hostname | tr 'A-Z' 'a-z')

declare -A IPMAP=(
  [utahime]=10.81.1.2 [shoko]=10.81.1.3 [gojo]=10.81.1.4
  [inumaki]=10.81.4.2 [geto]=10.81.4.3 [maki]=10.81.4.4
  [panda]=10.81.4.5 [nanami]=10.81.4.6 [todo]=10.81.4.7
  [kirara]=10.81.4.8 [yaga]=10.81.4.9 [tengen]=10.81.4.10
)

if [ "$NAME" = "jichi" ]; then
  echo "[jichi] Konfigurasi router..."
  # WAN eth0 dari NAT
  ip link set eth0 up
  if ! ip -4 addr show dev eth0 | grep -q "inet "; then
    dhclient eth0 2>/dev/null
    if ! ip -4 addr show dev eth0 | grep -q "inet "; then
      ip addr add 192.168.122.100/24 dev eth0
      ip route replace default via 192.168.122.1
    fi
  fi
  # Gateway Network 1-4
  for i in 1 2 3 4; do
    ip addr flush dev eth$i
    ip addr add 10.81.$i.1/24 dev eth$i
    ip link set eth$i up
  done
  # IP forwarding
  sysctl -w net.ipv4.ip_forward=1
  grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  # Source NAT
  iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  echo "nameserver 192.168.122.1" > /etc/resolv.conf

  echo "===== BUKTI ====="
  ip -br a
  ip route
  sysctl net.ipv4.ip_forward
  iptables -t nat -L POSTROUTING -n -v
  ping -c 3 8.8.8.8
  for ip in 10.81.1.2 10.81.1.3 10.81.1.4 10.81.4.2 10.81.4.3 10.81.4.4 10.81.4.5 10.81.4.6 10.81.4.7 10.81.4.8 10.81.4.9 10.81.4.10; do
    echo -n "Ping $ip -> "
    ping -c 1 -W 2 $ip >/dev/null 2>&1 && echo "OK" || echo "GAGAL"
  done
else
  IP=${IPMAP[$NAME]}
  if [ -z "$IP" ]; then echo "Hostname '$NAME' tidak dikenal"; exit 1; fi
  NET=$(echo $IP | cut -d. -f1-3)
  echo "[$NAME] Set IP $IP/24, gateway $NET.1"
  ip addr flush dev eth0
  ip addr add $IP/24 dev eth0
  ip link set eth0 up
  ip route replace default via $NET.1
  echo "nameserver 192.168.122.1" > /etc/resolv.conf

  echo "===== BUKTI ====="
  ip -br a
  ip route
  ping -c 2 $NET.1
  ping -c 2 8.8.8.8
  ping -c 2 google.com
fi
SCRIPT
chmod +x /root/soal_1.sh