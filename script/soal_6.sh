cat > /root/soal_6.sh <<'SCRIPT'
#!/bin/bash
# Soal 6 - Fixed address kugisaki (tambah ke konfigurasi yang ada)
CONF=/etc/dhcp/dhcpd.conf
if [ ! -f $CONF ]; then
  echo "dhcpd.conf tidak ada. Jalankan soal_7.sh dulu."
  exit 1
fi
if grep -q "host kugisaki" $CONF; then
  echo "Reservasi kugisaki sudah ada, dilewati."
else
  cat >> $CONF <<'EOT'

# Fixed address kugisaki (VIP)
host kugisaki {
    hardware ethernet 02:42:01:08:34:00;
    fixed-address 10.81.3.99;
}
EOT
fi
echo "===== VALIDASI ====="
dhcpd -t -cf $CONF || { echo "ERROR"; exit 1; }
service isc-dhcp-server restart
sleep 1
grep -n -A3 "host kugisaki" $CONF
ps aux | grep [d]hcpd
echo "Sekarang jalankan di kugisaki: sh /root/cek_client.sh"
SCRIPT
chmod +x /root/soal_6.sh