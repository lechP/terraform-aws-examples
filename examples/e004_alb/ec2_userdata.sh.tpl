#!/bin/bash
yum update -y
yum install -y nginx

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

HOSTNAME=$(hostname)

cat <<EOF >/usr/share/nginx/html/info.json
{
  "hostname": "$HOSTNAME",
  "instance_id": "$INSTANCE_ID"
}
EOF

systemctl enable nginx
systemctl start nginx
