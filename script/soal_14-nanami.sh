#!/bin/bash
apt update
apt install -y nginx php-fpm php-cli php-mysql curl iptables
ls -l /run/php/

mkdir -p /var/www/api
cat > /var/www/api/index.php <<'EOF'
<?php

header('Content-Type: application/json; charset=utf-8');

$workerName = gethostname();

$clientIp = $_SERVER['HTTP_X_FORWARDED_FOR']
    ?? $_SERVER['REMOTE_ADDR']
    ?? 'unknown';

$clientIp = trim(explode(',', $clientIp)[0]);

$proxyIp = $_SERVER['REMOTE_ADDR'] ?? 'unknown';

$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

$dbHost = '10.81.4.9';
$dbName = 'db_shibuya_k35';
$dbUser = 'k35';
$dbPass = 'passwordk35';

try {
    $db = new mysqli(
        $dbHost,
        $dbUser,
        $dbPass,
        $dbName
    );

    $db->set_charset('utf8mb4');

    $sql = "INSERT INTO request_logs
            (worker_name, client_ip, proxy_ip, user_agent)
            VALUES (?, ?, ?, ?)";

    $stmt = $db->prepare($sql);

    $stmt->bind_param(
        'ssss',
        $workerName,
        $clientIp,
        $proxyIp,
        $userAgent
    );

    $stmt->execute();

    $stmt->close();
    $db->close();

    http_response_code(200);

    echo json_encode([
        'status' => 'success',
        'worker' => $workerName,
        'client_ip' => $clientIp,
        'proxy_ip' => $proxyIp,
        'message' => 'Request berhasil dicatat'
    ]);

} catch (Throwable $e) {
    error_log('API/database error: ' . $e->getMessage());

    http_response_code(500);

    echo json_encode([
        'status' => 'error',
        'worker' => $workerName,
        'message' => 'Gagal memproses request'
    ]);
}
EOF

cat > /etc/nginx/sites-available/api.conf <<'EOF'
server {
    listen 80;
    server_name api.k35.com;

    root /var/www/api;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/api.conf \
  /etc/nginx/sites-enabled/api.conf

rm -f /etc/nginx/sites-enabled/default

nginx -t
service php8.4-fpm restart
service nginx restart

iptables -I INPUT 1 -p tcp --dport 80 \
  -s 10.81.4.3 -j ACCEPT

iptables -A INPUT -p tcp --dport 80 -j REJECT


php -r '
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $db = new mysqli(
        "10.81.4.9",
        "k35",
        "passwordk35",
        "db_shibuya_k35"
    );

    echo "Koneksi database berhasil\n";
    $db->close();
} catch (Throwable $e) {
    echo "Koneksi database gagal: " . $e->getMessage() . "\n";
    exit(1);
}
'