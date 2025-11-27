#!/bin/bash
yum install -y httpd
systemctl enable httpd
systemctl start httpd

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
