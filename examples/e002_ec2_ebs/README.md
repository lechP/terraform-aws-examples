# EC2 + EBS Example

This example demonstrates how to create an Amazon EC2 instance with an attached EBS volume using Terraform.
On startup, the instance formats, mounts, and makes the volume available at `/data`.
A simple web page served by Apache shows basic metadata and confirms the mounted disk.

---

## Architecture

- EC2 instance (Amazon Linux 2)
- 1 GiB EBS volume attached to the instance
- Security group allowing inbound HTTP (port 80)
- Apache (`httpd`) installed via user data
- Web page available over the public internet

---

## Files

| File           | Description                                   |
|----------------|-----------------------------------------------|
| `backend.tf`   | Configures S3 backend for Terraform state     |
| `main.tf`      | Main infrastructure: EC2, EBS, security group |
| `variables.tf` | Defines input variable `git_commit`           |
| `outputs.tf`   | Exposes public IP, URL, and volume ID         |

---

## Usage

### 1. Initialize Terraform, Validate, and Plan

```bash
terraform init
terraform validate
terraform plan -var="git_commit=$(git rev-parse HEAD)"
```

### 2. Apply (create the EC2 instance)

```bash
terraform apply -auto-approve -var="git_commit=$(git rev-parse HEAD)"
```

### 3. Verification

Once the deployment completes, Terraform outputs:
* `public_ip` — EC2 public IP
* `hello_url` — URL to open in your browser
* `volume_id` — ID of the EBS volume

Visit the `hello_url` in your browser.
You should see a page like this:

    Git commit SHA: <commit>
    Mounted volume:
    /dev/xvdf    1G    ...    /data

Instead of `/dev/xvdf` it can be `/dev/nvme1n1` depending on the instance type.

You can connect via SSH/EC2 Instance Connect to examine mounted volumes by calling `df -h`.

To further verify the EBS volume persistence, you can perform the following steps:
```
echo "Lorem ipsum" | sudo tee /data/test.txt
sudo reboot
[...wait for the instance to come back online...]
cat /data/test.txt
```
(When using EC2 Instance Connect, you may need to re-establish the session after reboot.)

### 4. Cleanup

Destroy all created resources:

```bash
terraform destroy -auto-approve
```

This will delete the EC2 instance and the attached EBS volume.
