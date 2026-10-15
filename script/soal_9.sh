#!/bin/bash
# Soal 9 - Troubleshooting DHCP Relay (K35)
# Pemakaian (urutan saat demo):
#   jichi  : bash /root/soal_9.sh baseline   -> kondisi sebelum gangguan
#   itadori: bash /root/soal_9.sh client     -> baseline client (opsional)
#   jichi  : bash /root/soal_9.sh stop       -> hentikan relay
#   tengen : bash /root/soal_9.sh capture    -> capture 15 detik (jalankan lalu langsung ke itadori)
#   jichi  : bash /root/soal_9.sh capture    -> capture eth2 15 detik (opsional)
#   itadori: bash /root/soal_9.sh client     -> GAGAL (catat gejala)
#   jichi  : bash /root/soal_9.sh start      -> pulihkan relay
#   tengen : bash /root/soal_9.sh capture
#   itadori: bash /root/soal_9.sh client     -> BERHASIL, pool & gateway benar

MODE="${1:-client}"
HOST="$(hostname)"
FILTER='udp port 67 or udp port 68'

relay_state() {
    echo "----- status relay -----"
    service isc-dhcp-relay status
    echo "----- proses dhcrelay -----"
    pgrep -a dhcrelay || echo "dhcrelay TIDAK berjalan"
}

case "$MODE" in
    baseline)
        relay_state
        echo "----- ip a -----"; ip a
        echo "----- forwarding -----"; sysctl net.ipv4.ip_forward
        ;;
    stop)
        service isc-dhcp-relay stop
        pkill dhcrelay 2>/dev/null
        sleep 1
        relay_state
        ;;
    start)
        service isc-dhcp-relay start
        sleep 2
        if ! pgrep dhcrelay >/dev/null; then
            echo "service gagal start, menjalankan dhcrelay manual dari /etc/default/isc-dhcp-relay"
            . /etc/default/isc-dhcp-relay
            IFARGS=""
            for i in $INTERFACES; do IFARGS="$IFARGS -i $i"; done
            dhcrelay -4 $OPTIONS $IFARGS $SERVERS
            sleep 1
        fi
        relay_state
        echo "----- konfigurasi relay -----"
        cat /etc/default/isc-dhcp-relay
        ;;
    capture)
        which tcpdump >/dev/null 2>&1 || (apt-get update -y && apt-get install -y tcpdump)
        if [ "$HOST" = "jichi" ]; then IFACE=eth2; else IFACE=eth0; fi
        echo "===== [$HOST] capture $IFACE selama 15 detik ====="
        timeout 15 tcpdump -i "$IFACE" -n "$FILTER"
        echo "===== capture selesai ====="
        ;;
    client)
        echo "===== [$HOST] Meminta lease baru ====="
        ip addr flush dev eth0
        ip link set eth0 up
        udhcpc -i eth0 -n -q -t 3 -T 3
        echo "exit code udhcpc: $?  (0 = berhasil, selain 0 = gagal)"
        echo "----- ip a -----"
        ip a show eth0
        echo "----- ip route -----"
        ip route
        ;;
    *)
        echo "Mode tidak dikenal: $MODE"
        echo "Gunakan: baseline | stop | start | capture | client"
        ;;
esac