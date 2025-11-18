# Terraform AWS Examples

A curated collection of minimal AWS Terraform examples.

| Example     | Description                        | Docs                                        |
|-------------|------------------------------------|---------------------------------------------|
| `ec2-basic` | Launch a single EC2 instance       | [README](examples/e001_ec2_basic/README.md) |
| `ec2-efs`   | EC2 instance with attached EFS     | [README](examples/e002_ec2_ebs/README.md)   |
| `ec2-lb`    | Load Balancer with two EC2 targets | TBD                                         |

## CI/CD Workflows (`.github/workflows`)

This repository includes three GitHub Actions workflows to standardize validation and lifecycle operations for each example.

### 1. `validate.yml` – Automatic syntax & formatting checks
Triggers: on every push, pull request, or manual dispatch.
Process:
- Discovers all example directories under `examples/*` dynamically.
- For each example: runs `terraform init -backend=false`, `terraform validate`, and `terraform fmt -check -recursive`.
Purpose: Ensures examples remain syntactically correct and properly formatted without needing backend configuration.

### 2. `deploy.yml` – Manual deployment of a single example
Trigger: manual (workflow_dispatch) with required input `example_name` (folder name under `examples/`).
Process:
- Configures AWS credentials via OIDC assuming role `TerraformCiRole` in account ID stored in `secrets.ACCOUNT_ID`.
- Runs `terraform init`, `terraform plan`, and `terraform apply -auto-approve`, passing a `git_commit` variable for traceability.
Usage: From the GitHub UI select the workflow, provide `example_name` (e.g. `e001_ec2_basic`).

### 3. `destroy.yml` – Manual teardown of a single example
Trigger: manual (workflow_dispatch) with required input `example_name`.
Process:
- Assumes the same role via OIDC.
- Runs `terraform init` then `terraform destroy -auto-approve`.
Usage: Invoke after testing to avoid orphaned resources (and costs $$$), using the same `example_name`.

### AWS Credentials & OIDC
Both deploy and destroy rely on GitHub OIDC federation. Prerequisites:
- An IAM role named `TerraformCiRole` trusted for GitHub OIDC and granting necessary Terraform actions.
- Repository secret `ACCOUNT_ID` containing your AWS account ID.

### Example Folder Naming
Pass only the folder name (e.g. `e001_ec2_basic`) to `example_name`; workflows internally `cd examples/${example_name}`.
