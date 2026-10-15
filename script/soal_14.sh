#!/bin/bash

apt-get update
apt install -y nginx php-fpm php-cli php-mysql curl iptables
service nginx start
service php*-fpm start
ls /etc/init.d/*fpm*

mkdir -p /var/www/frontend

cat > /var/www/frontend/index.php <<'EOF'
<?php
$hostname = gethostname();
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Frontend Maki</title>
</head>
<body>
    <h1>Frontend</h1>
    <p>Request diproses oleh worker:</p>
    <h2><?= htmlspecialchars($hostname, ENT_QUOTES, 'UTF-8') ?></h2>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/frontend

cat > /etc/nginx/sites-available/frontend.conf <<'EOF'
server {
    listen 80;
    server_name jujutsu.k35.com;

    root /var/www/frontend;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        try_files $uri =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/frontend.conf \
    /etc/nginx/sites-enabled/frontend.conf

rm -f /etc/nginx/sites-enabled/default

nginx -t
service php8.4-fpm restart
service nginx restart

# Izinkan koneksi dari localhost
iptables -C INPUT -i lo -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 1 -i lo -j ACCEPT

# Izinkan Gojo mengakses port 80
iptables -C INPUT -p tcp --dport 80 \
    -s 10.81.1.4 -j ACCEPT 2>/dev/null ||
iptables -I INPUT 2 -p tcp --dport 80 \
    -s 10.81.1.4 -j ACCEPT

# Tolak akses port 80 dari sumber lain
iptables -C INPUT -p tcp --dport 80 \
    -j REJECT 2>/dev/null ||
iptables -A INPUT -p tcp --dport 80 -j REJECT

curl -i -H 'Host: jujutsu.k35.com' http://127.0.0.1/

echo ""
echo "Konfigurasi frontend Maki berhasil."