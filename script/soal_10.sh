#!/bin/bash
# Soal 10 - Persistence setelah restart (K35)
# Pemakaian:
#   tengen & jichi : bash /root/soal_10.sh enable   -> aktifkan autostart (sekali saja)
#   tengen & jichi : bash /root/soal_10.sh before   -> catat kondisi sebelum restart
#   (restart jichi lalu tengen lewat GNS3: Stop -> Start, buka console)
#   tengen & jichi : bash /root/soal_10.sh after    -> verifikasi setelah restart
#   semua client N2-N3 : bash /root/soal_10.sh client -> minta lease & uji konektivitas
#   tengen : bash /root/soal_10.sh lease            -> bukti lease time & fixed address

MODE="${1:-client}"
HOST="$(hostname)"
MARK="# K35-soal10-autostart"

enable_autostart() {
    if [ "$HOST" = "tengen" ]; then
        SVC=isc-dhcp-server
        LINE='service isc-dhcp-server status >/dev/null 2>&1 || service isc-dhcp-server start'
    elif [ "$HOST" = "jichi" ]; then
        SVC=isc-dhcp-relay
        LINE='service isc-dhcp-relay status >/dev/null 2>&1 || service isc-dhcp-relay start'
    else
        echo "Mode enable hanya untuk tengen dan jichi."; return
    fi
    systemctl enable "$SVC" 2>/dev/null || update-rc.d "$SVC" enable
    if ! grep -q "$MARK" /root/.bashrc; then
        {
            echo "$MARK"
            echo "$LINE"
        } >> /root/.bashrc
        echo "Baris autostart ditambahkan ke /root/.bashrc"
    else
        echo "Baris autostart sudah ada di /root/.bashrc"
    fi
    echo "----- ekor .bashrc -----"
    tail -n 6 /root/.bashrc
    echo "----- cek enable -----"
    systemctl is-enabled "$SVC" 2>&1
    ls /etc/rc2.d/ | grep -i dhcp
}

check_state() {
    if [ "$HOST" = "tengen" ]; then
        echo "----- status isc-dhcp-server -----"; service isc-dhcp-server status
        echo "----- proses dhcpd -----"; pgrep -a dhcpd || echo "dhcpd TIDAK berjalan"
        echo "----- enabled? -----"; systemctl is-enabled isc-dhcp-server 2>&1
        echo "----- dhcpd -t -----"; dhcpd -t
        echo "----- ip a -----"; ip a
        echo "----- ip route -----"; ip route
        echo "----- ping gateway Network 4 -----"; ping -c 2 10.81.4.1
    elif [ "$HOST" = "jichi" ]; then
        echo "----- status isc-dhcp-relay -----"; service isc-dhcp-relay status
        echo "----- proses dhcrelay -----"; pgrep -a dhcrelay || echo "dhcrelay TIDAK berjalan"
        echo "----- enabled? -----"; systemctl is-enabled isc-dhcp-relay 2>&1
        echo "----- konfigurasi relay -----"; cat /etc/default/isc-dhcp-relay
        echo "----- ip a -----"; ip a
        echo "----- ip route -----"; ip route
        echo "----- ip_forward -----"; sysctl net.ipv4.ip_forward
        echo "----- NAT -----"; iptables -t nat -L POSTROUTING -n
        . /etc/default/isc-dhcp-relay
        echo "----- ping tengen ($SERVERS) -----"; ping -c 2 $SERVERS
        echo "----- ping internet -----"; ping -c 2 8.8.8.8
    else
        echo "Mode ini hanya untuk tengen dan jichi."
    fi
}

case "$MODE" in
    enable) enable_autostart ;;
    before|after) echo "===== [$HOST] kondisi: $MODE restart ====="; check_state ;;
    lease)
        echo "===== Lease di tengen ====="
        grep -E "^lease|starts|ends|hardware ethernet|client-hostname" /var/lib/dhcp/dhcpd.leases
        ;;
    client)
        echo "===== [$HOST] Meminta lease baru ====="
        ip addr flush dev eth0
        ip link set eth0 up
        udhcpc -i eth0 -n -q 2>&1
        echo "----- MAC -----"; ip link show eth0 | grep ether
        echo "----- ip a -----"; ip a show eth0
        echo "----- ip route -----"; ip route
        GW=$(ip route | awk '/default/ {print $3; exit}')
        echo "----- ping gateway ($GW) -----"; ping -c 2 "$GW"
        echo "----- ping internet -----"; ping -c 2 8.8.8.8
        ;;
    *)
        echo "Mode tidak dikenal: $MODE"
        echo "Gunakan: enable | before | after | lease | client"
        ;;
esac