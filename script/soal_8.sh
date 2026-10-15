#!/bin/bash
# Soal 8 - Packet capture DHCP DORA (K35)
# Pemakaian:
#   tengen  : bash /root/soal_8.sh          (jalankan DULUAN, menunggu 4 packet)
#   jichi   : bash /root/soal_8.sh          (opsional, capture sisi client eth2)
#   client  : bash /root/soal_8.sh          (itadori, jalankan SETELAH tengen siap)
# Override peran manual: bash /root/soal_8.sh tengen|jichi|client

ROLE="${1:-$(hostname)}"
FILTER='udp port 67 or udp port 68'

need_tcpdump() {
    which tcpdump >/dev/null 2>&1 || (apt-get update -y && apt-get install -y tcpdump)
}

case "$ROLE" in
    tengen)
        need_tcpdump
        echo "===== [tengen] Menunggu DORA (4 packet) pada eth0 ====="
        tcpdump -i eth0 -n -vvv -c 4 "$FILTER" 2>&1 | tee /root/dhcp-dora-K35.txt
        echo
        echo "===== Ringkasan field penting ====="
        grep -E "xid|Gateway-IP|Your-IP|Server-ID|Lease-Time|Requested-IP|DHCP-Message" /root/dhcp-dora-K35.txt
        echo
        echo "Hasil lengkap tersimpan di /root/dhcp-dora-K35.txt"
        ;;
    jichi)
        need_tcpdump
        echo "===== [jichi] Capture sisi client (eth2) ====="
        tcpdump -i eth2 -n -vvv -c 4 "$FILTER" 2>&1 | tee /root/dhcp-dora-eth2-K35.txt
        echo
        grep -E "xid|Gateway-IP|Your-IP|Server-ID|Lease-Time|DHCP-Message" /root/dhcp-dora-eth2-K35.txt
        ;;
    *)
        echo "===== [client] Meminta lease baru ====="
        ip addr flush dev eth0
        ip link set eth0 up
        udhcpc -i eth0 -n -q
        echo "----- ip a -----"
        ip a show eth0
        echo "----- ip route -----"
        ip route
        ;;
esac