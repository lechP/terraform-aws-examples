#!/bin/bash
set -xe

# --- Configuration ---
EFS_ID="${efs_id}"        # Will be injected by Terraform
AWS_REGION="${aws_region}"        # Will be injected by Terraform
MOUNT_POINT="/data"

# --- Prepare system ---
yum update -y
yum install -y amazon-efs-utils nfs-utils

# --- Create mount point ---
mkdir -p ${MOUNT_POINT}

# --- Wait for EFS DNS to resolve (mount target readiness) ---
# This loop retries DNS resolution for up to ~2 minutes.
for i in {1..24}; do
    if getent hosts ${EFS_ID}.efs.${AWS_REGION}.amazonaws.com; then
        echo "EFS DNS resolved."
        break
    fi
    echo "Waiting for EFS mount target..."
    sleep 5
done

# --- Mount the EFS filesystem ---
# Using TLS for encryption in transit
mount -t efs -o tls ${EFS_ID}:/ ${MOUNT_POINT}

# --- Verify mount success ---
df -h | grep ${MOUNT_POINT} || {
    echo "Mount failed, retrying once..."
    sleep 5
    mount -t efs -o tls ${EFS_ID}:/ ${MOUNT_POINT}
}

# --- Write a test file ---
echo "EFS mounted successfully on $(hostname) at $(date)" > ${MOUNT_POINT}/status.txt

# --- Ensure EFS mounts on reboot ---
echo "${EFS_ID}:/ ${MOUNT_POINT} efs _netdev,tls 0 0" >> /etc/fstab
