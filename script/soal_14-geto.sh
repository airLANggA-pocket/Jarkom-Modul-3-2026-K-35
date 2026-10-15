#!/bin/bash

apt-get update -y
apt install -y nginx curl

cat > /etc/nginx/conf.d/api-lb.conf <<'EOF'
upstream api_cluster {
    server 10.81.4.6:80 weight=3;
    server 10.81.4.7:80 weight=1;
    server 10.81.4.8:80;
}

server {
    listen 80;
    server_name api.k35.com;

    location / {
        proxy_pass http://api_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t
service nginx restart
service nginx status
