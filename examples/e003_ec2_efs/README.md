# Example: Two EC2 Instances Sharing an EFS File System (Terraform)

This example demonstrates how to provision two Amazon EC2 instances in different Availability Zones that share a single Amazon EFS (Elastic File System).
Each instance mounts the EFS file system to `/data` using the `amazon-efs-utils` package.

---

## Architecture

- **VPC**: Default VPC used for simplicity.
- **Subnets**: Default subnets in two Availability Zones.
- **EFS File System**: One shared file system.
- **Mount Targets**: One per subnet (one per AZ).
- **EC2 Instances**: Two `t3.micro` instances (Amazon Linux 2), each mounting the EFS.
- **Security Groups**:
  - `instances_sg` — allows SSH (22) and any egress.
  - `efs_sg` — allows inbound NFS (2049/tcp) from EC2 instances.

---

## Prerequisites

1. **Terraform** ≥ 1.6.0
2. **AWS CLI** configured with credentials allowing:
   - EFS management (`elasticfilesystem:*`)
   - ENI management (`ec2:CreateNetworkInterface`, `ec2:Describe*`)
   - EC2 instance management (`ec2:*`)
   - IAM permissions if creating execution roles
3. An existing S3 bucket and DynamoDB table for Terraform backend (as configured in `backend.tf`):
   ```hcl
   bucket         = "lpi-tfstate-3e1989"
   dynamodb_table = "tf-locks"
   ```
4. Default VPC must exist in the region (`eu-west-3`).
---

## Files Overview

| File                  | Purpose                                                                                        |
|-----------------------|------------------------------------------------------------------------------------------------|
| `main.tf`             | Main Terraform configuration: VPC data, security groups, EFS, mount targets, and EC2 instances |
| `ec2_userdata.sh.tpl` | User data template for automatic EFS mounting                                                  |
| `backend.tf`          | Terraform backend configuration (S3 + DynamoDB for state and locking)                          |
| `outputs.tf`          | Outputs for EFS and mount targets                                                              |

---

## Deployment Steps

### 1. Initialize Terraform, Validate, and Plan

```bash
terraform init
terraform validate
terraform plan
```

### 2. Apply (create the EC2 instance)

```bash
terraform apply -auto-approve
```

   Terraform will:
   - Create security groups
   - Provision an EFS file system
   - Create mount targets in two subnets
   - Launch two EC2 instances
   - Mount the EFS on each instance at `/data`

---

## Verification

### 1. SSH into an instance
Locate the instance’s private IP or connect through EC2 Instance Connect.

### 2. Confirm EFS mount
```bash
df -h | grep /data
```
Expected output (approximate):
```
127.0.0.1:/  8.0E  ...  /data
```

```bash
ls /var/run/efs/
```
You should see the EFS file system ID listed.

### 3. Test file sharing
On **Instance 1**:
```bash
sudo mkdir -p /data/shared
sudo chown ec2-user:ec2-user /data/shared
echo "Hello from $(hostname)" >> /data/shared/note.txt
```
First you create a directory to which then you give ownership to the `ec2-user` so that you can write files there without `sudo`.

On **Instance 2**:
```bash
cat /data/shared/note.txt
```
You should see the content written by Instance 1, confirming shared storage.

---

## Cleanup

When finished, destroy all resources to avoid charges:
```bash
terraform destroy
```

---

## Notes & Troubleshooting

- **DNS resolution delay**: The `user_data` script retries for ~2 minutes while EFS mount targets propagate.
- **EFS mount persistence**: To make the mount permanent, add an `/etc/fstab` entry:
  ```bash
  echo "${EFS_ID}:/ /data efs _netdev,tls 0 0" >> /etc/fstab
  ```

Then verify with:
```bash
mount -a
```

---

## Key Learning Points

- How to use Terraform’s `templatefile()` to inject dynamic values into EC2 user data.
- How EFS mount targets relate to subnets and AZs.
- Correct security group setup for NFS access.
- How to manage resource dependencies with `depends_on`.
