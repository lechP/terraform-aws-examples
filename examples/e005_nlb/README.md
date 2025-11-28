# Example e005 --- Network Load Balancer with Two EC2 Targets

This example demonstrates how to deploy an **AWS Network Load Balancer** (NLB) distributing traffic across **two target groups** using weighted formatting.\
Each EC2 instance underneath serves a simple HTML page containing its hostname.\
A helper Python script (`examples/e005_nlb/demo/count_traffic_distribution.py`) verifies traffic distribution across all backend instances.

## Architecture Overview

The example deploys the following resources:

* Network Load Balancer (public)
* Three EC2 instances in separate subnets
  * Instances have SSM enabled for debugging
* Two target groups with TCP health checks simulating `main` and `canary` targets
  * Traffic is distributed across both target groups with 90% going to `main` and 10% to `canary`
* Security group allowing inbound HTTP (`80`) to instances
* `user_data` script that installs httpd and serves an HTML page with the instance hostname
* Listener on port **80** forwarding traffic to the target group

This time, unlike the previous examples, all resources run inside a **dedicated VPC** with public and private subnets across three Availability Zones.
`module "vpc"` is used to provision the VPC and subnets.

## How It Works

### 1. EC2 Instances

Each instance uses a `user_data` script to:

-   Install `httpd`
-   Render a simple HTML page that includes the instance hostname
-   Serve it via HTTP on port 80

The target group health checks ensure only healthy instances receive traffic.

### 2. Network Load Balancer

The NLB:

-   Listens on **port 80**
-   Forwards all traffic to the target groups
-   Provides high-performance, low-latency load balancing at Layer 4

This showcases simple HTTP serving behind an L4 load balancer.

### 3. Testing Load Distribution

A Python script (`examples/e005_nlb/demo/count_traffic_distribution.py`) sends multiple requests to the NLB and counts how many responses come from each instance by parsing the hostname from the HTML body.

Example:

```bash
uv run examples/e005_nlb/demo/count_traffic_distribution.py --url $(terraform output -raw nlb_dns_name)
```

This confirms that the NLB distributes traffic across all targets.

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

    nlb_dns_name = <your-load-balancer-dns>

Use this value when testing.

## Testing the setup

## 1. Check backend responses

```bash
curl http://<nlb_dns_name>/
```

You should see an HTML page that includes the instance hostname.

## 2. Test traffic distribution

```bash
uv run examples/e005_nlb/demo/count_traffic_distribution.py --url $(terraform output -raw nlb_dns_name)
```

Sample output:

```plaintext
=== Results ===
ip-10-100-90-20.eu-west-3.compute.internal:    90  ( 45.0%)
ip-10-100-66-78.eu-west-3.compute.internal:    87  ( 43.5%)
ip-10-100-99-173.eu-west-3.compute.internal:    23  ( 11.5%)
```

You can also disrupt one instance:
* e.g., stop it from the AWS Console
* or run `sudo systemctl stop httpd` within the instance and wait for the health check to fail

and rerun the script to observe how all traffic goes to the remaining healthy instances.


## Cleanup

``` bash
terraform destroy
```

This removes all provisioned resources, including EC2 instances, NLB, security groups and VPC.

## Notes
* NLB operates at Layer 4; header-based routing or fixed responses (like ALB) are not available.
* Dedicated VPC is created for this example; having NAT gateway incurs additional costs.
* The script in examples/e005_nlb/demo/count_traffic_distribution.py parses the hostname from the HTML to count per-target responses.
