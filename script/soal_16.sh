#!/bin/bash

# gojo
cat > /etc/nginx/conf.d/reverse-proxy.conf <<'EOF'
upstream web_cluster {
    server 10.81.4.4:80;
    server 10.81.4.5:80;
}

upstream api_gateway {
    server 10.81.4.3:80;
}

server {
    listen 80;
    server_name jujutsu.k35.com www.jujutsu.k35.com;

    # API diteruskan langsung ke Geto
    location = /api {
        proxy_pass http://api_gateway;

        proxy_set_header Host api.k35.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ^~ /api/ {
        proxy_pass http://api_gateway;

        proxy_set_header Host api.k35.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Request lainnya menuju frontend Maki/Panda
    location / {
        proxy_pass http://web_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
# Virtual Host Domain API
server {
    listen 80;
    server_name api.k35.com;

    location / {
        proxy_pass http://api_gateway;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t

service nginx reload
service nginx status

nginx -T | grep -A 45 \
  'server_name jujutsu.k35.com'
