# EC2 Basic Example

This example demonstrates how to launch a single Amazon EC2 instance using Terraform.
The instance runs a simple HTTP server that displays metadata such as the Git commit, hostname, and startup timestamp.

---

## Architecture

- Creates an EC2 instance in the default VPC and first available subnet.
- Associates a security group allowing inbound HTTP (port 80) from anywhere.
- Installs and starts Apache (`httpd`) via user data.
- Generates a small status page accessible over the public Internet.

---

## Files

| File           | Description                                                                  |
|----------------|------------------------------------------------------------------------------|
| `main.tf`      | Defines provider, networking data sources, security group, and EC2 instance. |
| `backend.tf`   | Configures the S3 backend and DynamoDB table for Terraform state management. |
| `variables.tf` | Defines input variables (e.g., `git_commit`).                                |
| `outputs.tf`   | Exposes instance public IP and a direct HTTP URL.                            |

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

### 3. Check the result

After creation, Terraform outputs two values:

* `public_ip` — The EC2 instance’s public IP address.
* `hello_url` — A ready-to-open HTTP link.

Visit the URL in your browser. You should see a page similar to:

    Hello from Terraform!
    Git commit SHA: <your SHA>
    Startup timestamp: <UTC time>
    Hostname: <instance hostname>

#### Verification Checklist

* [ ] The EC2 instance appears in the AWS Console under EC2 → Instances.
* [ ] The security group hello-sg is attached to it and allows inbound HTTP.
* [ ] The output URL responds with a web page from the instance.


### 4. Destroy (teardown the EC2 instance)

To tear down all created resources:
```bash
terraform destroy -auto-approve
```

After terraform destroy, you can check if both the instance and its security group are gone.
