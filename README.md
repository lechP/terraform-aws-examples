# Terraform AWS Examples

Currently, a simple example of launching an EC2 instance with Terraform, plus GitHub Actions workflows to validate, deploy, and destroy.
Goal is to provide multiple examples of AWS based infrastructure as code.

## Workflows
- **Validate** (`.github/workflows/validate.yml`): Validates Terraform code on push/PR.
- **Deploy** (`.github/workflows/deploy.yml`): Manual; runs resources provisioning.
- **Destroy** (`.github/workflows/destroy.yml`): Manual; teardown.
