#!/bin/bash

yum clean all
yum makecache

for attempt in {1..20}; do # await up to ~3 minutes for VPC to properly configure
  yum install -y httpd && break
  echo "yum install failed, retry $attempt..."
  sleep 5
done

systemctl enable httpd
systemctl start httpd

mkdir -p /var/www/html

HOSTNAME=$(hostname)
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

cat <<HTML > /var/www/html/index.html
<html>
<head><title>NLB Demo</title></head>
<body>
<h1>Hello from EC2 behind an NLB</h1>
<p>Hostname: $HOSTNAME</p>
<p>Startup timestamp: $TIMESTAMP</p>
</body>
</html>
HTML
