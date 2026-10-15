#!/bin/bash

# GOJO
# Membuat backup konfigurasi lama
cp /etc/nginx/conf.d/reverse-proxy.conf \
   /etc/nginx/conf.d/reverse-proxy.conf.backup

# Membuat direktori cache
mkdir -p /var/cache/nginx

# Konfigurasi reverse proxy, cache, dan rate limiting
cat > /etc/nginx/conf.d/reverse-proxy.conf <<'EOF'
proxy_cache_path /var/cache/nginx levels=1:2
    keys_zone=frontend_cache:10m inactive=60m;

limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

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

    location = /api {
        limit_req zone=api_limit;
        limit_req_status 503;

        proxy_pass http://api_gateway;
        proxy_set_header Host api.k35.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ^~ /api/ {
        limit_req zone=api_limit;
        limit_req_status 503;

        proxy_pass http://api_gateway;
        proxy_set_header Host api.k35.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://web_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_cache frontend_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;

        add_header X-Cache-Status $upstream_cache_status always;
    }
}

server {
    listen 80;
    server_name api.k35.com;

    location / {
        limit_req zone=api_limit;
        limit_req_status 503;

        proxy_pass http://api_gateway;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t
service nginx reload
