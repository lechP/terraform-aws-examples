# Example e004 --- Application Load Balancer with Two EC2 Targets

This example demonstrates how to deploy an **AWS Application Load
Balancer** (ALB) distributing traffic across **two EC2 instances**.\
Each instance serves a simple JSON document containing its hostname and
instance ID.\
The ALB is configured with:

-   A listener on port **80**
-   A default action forwarding traffic to the target group
-   An additional listener rule returning a **custom fixed response**
    for the `/error` path

A helper Python script (`count_instances.py`) is included to verify
traffic distribution across both backend instances.

## Architecture Overview

The example deploys the following resources:

-   Application Load Balancer (public)
-   Target group with health checks on `/info.json`
-   Two EC2 instances in separate subnets
-   Security groups for the ALB and the instances - ALB allows inbound HTTP (80), instances
    allow inbound HTTP (80) from the ALB only
-   Custom user_data script that installs Nginx and serves `/info.json`
-   Listener rule returning a fixed HTML response for `/error`

All resources run inside the **default VPC** and use **default subnets**
across two Availability Zones.

## How It Works

### 1. EC2 Instances

Each instance uses a user_data script:

-   Installs Nginx\
-   Collects metadata (hostname, instance ID)\
-   Writes `/usr/share/nginx/html/info.json`\
-   Serves it via HTTP on port 80

The ALB health checks query `/info.json` and only forward traffic to
healthy instances.

### 2. Application Load Balancer

The ALB:

-   Listens on **port 80**\
-   Forwards all traffic by default to the target group\
-   Responds to `/error` with a **fixed HTML response** defined directly
    in the listener rule

This demonstrates how ALB can serve error pages without contacting
backend servers.

### 3. Testing Load Distribution

A Python script (`count_instances.py`) sends multiple requests to the
ALB and prints how many responses come from each EC2 instance.

Example:

``` bash
uv run examples/e004_alb/count_instances.py --url $(terraform output -raw alb_dns_name)
```

This confirms that the ALB distributes traffic across both targets.

## Deployment

### 1. Initialize Terraform, Validate, and Plan

```bash
terraform init
terraform validate
terraform plan
```

### 2. Apply infrastructure

```bash
terraform apply
```

After completion, Terraform outputs:

    alb_dns_name = <your-load-balancer-dns>

Use this value when testing.

## Testing the Setup

### 1. Check backend responses

``` bash
curl http://<alb_dns_name>/info.json
```

Expected response:

``` json
{
  "hostname": "ip-172-31-xx-xx",
  "instance_id": "i-0abcdef12345"
}
```

### 2. Test the custom error route

``` bash
curl http://<alb_dns_name>/error
```

You should see the custom ALB-level HTML response.

### 3. Test traffic distribution

``` bash
uv run examples/e004_alb/count_instances.py --url $(terraform output -raw alb_dns_name)
```

Sample output:

    === Load balancer calls results ===
    ip-172-31-21-101: 26 requests
    ip-172-31-45-222: 24 requests

## Cleanup

``` bash
terraform destroy
```

This removes all provisioned resources, including EC2 instances, ALB,
and security groups.

## Notes

-   Instances no longer expose SSH or public IPs (ALB-only access).\
-   Default VPC and subnets are used for simplicity; a production
    version should define its own VPC.\
-   Demonstrates ALB fixed responses, custom rules, and backend health
    checks.
