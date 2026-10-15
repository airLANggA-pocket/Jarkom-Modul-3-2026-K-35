#!/bin/sh

# KUSAKABE
cat > soal_20.sh <<'EOF'
#!/bin/sh

# KUSAKABE
apk add --no-cache apache2-utils curl

echo "=== Benchmark Frontend ==="
ab -n 600 -c 30 -H "Host: jujutsu.k35.com" http://10.81.1.4/ > frontend.txt

echo "=== Benchmark API ==="
ab -n 600 -c 30 -H "Host: jujutsu.k35.com" http://10.81.1.4/api > api.txt

echo "=== Hasil Frontend ==="
grep -E "Requests per second|Time per request|Failed requests|Non-2xx responses" frontend.txt

echo "=== Hasil API ==="
grep -E "Requests per second|Time per request|Failed requests|Non-2xx responses" api.txt

echo "Hasil lengkap tersimpan di frontend.txt dan api.txt"
EOF

# KUSAKABE
cat >> soal_20_1.sh <<'EOF'

#!/bin/bash
ab -n 600 -c 30 -H "Host: jujutsu.k35.com" \
http://10.81.1.4/api > baseline.txt

grep -E "Complete requests|Failed requests|Non-2xx responses|Requests per second|Time per request" baseline.txt
EOF

# GOJO
cat > soal_20.sh <<'EOF'
#!/bin/sh

CONF=/etc/nginx/conf.d/reverse-proxy.conf

if [ "$1" = "off" ]; then
    cp "$CONF" /tmp/proxy-backup-soal20
    sed -i '/limit_req zone=api_limit/d; /limit_req_status 503/d' "$CONF"
elif [ "$1" = "on" ]; then
    cp /tmp/proxy-backup-soal20 "$CONF"
else
    echo "Gunakan: ./soal_20.sh off atau on"
    exit 1
fi

nginx -t && service nginx reload
EOF
