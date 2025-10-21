# Hello CI/CD (Template)

Minimal GitHub Actions CI/CD to be expanded into Terraform later.

## Workflows
- **CI** (`.github/workflows/ci.yml`): Runs on PRs/pushes, prints “hello world”.
- **Deploy** (`.github/workflows/deploy.yml`): Manual or on tags; placeholder for provisioning later.
- **Destroy** (`.github/workflows/destroy.yml`): Manual; placeholder for teardown later.

### Quick start
1. Create the repo and push (see commands below).
2. Open the **Actions** tab and run:
   - **Hello CI**: happens automatically on push/PR.
   - **Deploy (hello)**: **Run workflow** → pick an environment (dev/stage/prod).
   - **Destroy (hello)**: **Run workflow** → pick the same environment.

> When ready for Terraform, replace the `scripts/hello_*.sh` bodies (or commented steps in workflows) with `terraform init/plan/apply/destroy` and wire secrets via repo **Settings → Secrets and variables → Actions**.

