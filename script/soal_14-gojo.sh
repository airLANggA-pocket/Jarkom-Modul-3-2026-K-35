#!/bin/bash
apt-get  update -y
apt install -y nginx curl

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
    server_name jujutsu.k35.com;

    location / {
        proxy_pass http://web_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

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
service nginx restart
service nginx status
