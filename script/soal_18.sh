#!/bin/bash

cat <<'EOF' > /etc/nginx/conf.d/api-lb.conf
upstream api_cluster {
    server 10.81.4.6:80 max_fails=2 fail_timeout=5s;
    server 10.81.4.7:80 max_fails=2 fail_timeout=5s;
    server 10.81.4.8:80 backup;
}

# Hanya percaya header alamat klien dari Gojo
set_real_ip_from 10.81.1.4;
real_ip_header X-Real-IP;
real_ip_recursive off;

server {
    listen 80;
    server_name api.k35.com;

    location / {
        proxy_pass http://api_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t

service nginx reload