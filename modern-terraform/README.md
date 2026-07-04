# Modern: Terraform EC2 Provisioning

A ground-up implementation of the same DevOps tooling fleet from the `legacy-salt-cloud/`
piece in this repo, rebuilt using Terraform to manage the full stack — networking,
compute, remote state, and modules — rather than instances alone.

---

## Skills Demonstrated

- **Remote S3 backend with native S3 locking** — state stored in S3 using Terraform's
  `use_lockfile` mechanism (available since Terraform 1.10), deliberately avoiding the
  DynamoDB-based locking pattern that has since been deprecated in favor of S3-native locking
- **Bootstrap pattern** — resolves the chicken-and-egg problem of using S3 as a remote
  backend when the bucket itself needs to be provisioned by Terraform; a separate `bootstrap/`
  config creates the state bucket with a local backend, after which the main config initializes
  against it
- **Module design** — networking and compute concerns separated into distinct reusable modules
  under `modules/`, with the root config wiring them together via module output references
- **VPC architecture** — public/private subnet tiering across two AZs, Internet Gateway for
  public egress, NAT Gateway for private subnet outbound access, and a bastion security group
  pattern that gates SSH into private instances through a dedicated bastion SG rather than
  direct CIDR references
- **Dynamic AMI lookup** — `data "aws_ami"` with specific name-pattern and virtualization-type
  filters selects the most recent Amazon Linux 2023 AMI at apply time; no AMI ID is hardcoded
  anywhere in the configuration
- **`for_each` over a map variable** — EC2 instances are provisioned from a
  `map(object({...}))` input, giving each instance a stable, purpose-keyed address in state
  (e.g., `aws_instance.devops_tools["ci-cd"]`) rather than a fragile numeric index; adding
  or removing a single instance does not shift the addresses of others the way `count` would
- **`terraform state mv`** — used during the module refactor to migrate all 21 resource
  addresses from flat (e.g., `aws_vpc.main`) to module-qualified paths (e.g.,
  `module.networking.aws_vpc.main`) without touching real infrastructure; `terraform plan`
  confirmed "No changes" after the full migration
- **LocalStack** — all phases developed and tested against LocalStack, enabling a full
  apply/destroy lifecycle — including NAT Gateway, EC2 instances, and remote state
  operations — without AWS costs or credentials

---

## Architecture overview

The configuration is organized into three layers.

**Bootstrap (`bootstrap/`)** is a standalone Terraform config with a local backend. Its
sole job is to create the S3 bucket (`epe-mt-terraform-state-01`) that the main config
uses as its remote backend, along with versioning, AES256 server-side encryption, and
public access block. It is applied once before the main config is initialized, and its
own state remains local.

**The main config** holds only provider configuration and module calls. The root `main.tf`
wires the two modules together by passing networking outputs as compute inputs; no resources
are defined at the root level.

**The networking module (`modules/networking/`)** provisions the full network foundation:
a VPC (`10.0.0.0/16`), two public and two private subnets spread across `us-east-1a` and
`us-east-1b`, an Internet Gateway with a public route table and associations, an Elastic IP
and NAT Gateway (in the first public subnet) with a private route table and associations,
and two security groups — one for the bastion host (SSH ingress from `var.admin_cidr` only,
unrestricted egress) and one for private compute instances (SSH ingress from the bastion SG
only, unrestricted egress via NAT). The module exports `private_subnet_ids` and
`private_compute_sg_id` for consumption by the compute module.

**The compute module (`modules/compute/`)** provisions the EC2 instances. An `aws_ami`
data source selects the most recent Amazon Linux 2023 x86_64 HVM image at apply time. A
single `aws_instance` resource uses `for_each` over the `var.instances` map to provision
five purpose-keyed instances — source-control, artifact-repo, directory-services, ci-cd,
monitoring — all placed in the first private subnet with the private compute security group
applied. Subnet and security group IDs are passed in from the networking module's outputs
rather than referenced directly, keeping the modules decoupled.

The networking/compute separation keeps network changes isolated from compute changes and
makes each module independently readable.

---

## Prerequisites

- Terraform >= 1.15
- AWS CLI configured, or LocalStack for local testing
- Docker (for running LocalStack)

---

## Local testing with LocalStack

All phases of this configuration were developed and tested against LocalStack using a
full apply/destroy lifecycle.

**1. Start LocalStack:**
```bash
docker run -d --name localstack -p 4566:4566 \
  -e LOCALSTACK_AUTH_TOKEN="$LOCALSTACK_AUTH_TOKEN" \
  localstack/localstack
```

**2. Bootstrap — provision the S3 state bucket.** The bootstrap config has its own
`provider_override.tf` (gitignored) pointing at LocalStack. From `bootstrap/`:
```bash
terraform init
terraform apply
```

**3. Create `provider_override.tf`** (gitignored — never commit) in `modern-terraform/`.
This overrides the provider block to point all API calls at LocalStack:
```hcl
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }
}
```

**4. Create `backend_local.hcl`** (gitignored — never commit) in `modern-terraform/`.
This overrides the S3 backend configuration to use LocalStack's endpoints:
```hcl
endpoints = {
    s3 = "http://localhost:4566"
}
access_key                  = "test"
secret_key                  = "test"
skip_credentials_validation = true
skip_requesting_account_id  = true
use_path_style              = true
```

**5. Create `terraform.tfvars`** (gitignored — never commit). The `admin_cidr` variable
has an intentionally invalid placeholder default (`"YOUR_IP_HERE/32"`) that causes a
plan-time failure if not explicitly overridden, which is preferable to silently defaulting
to an open CIDR. Copy the example file to get started:
```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set admin_cidr to a valid CIDR (any value works in LocalStack)
```

**6. Initialize and apply:**
```bash
terraform init -backend-config=backend_local.hcl
terraform apply
```

> **Note:** NAT Gateway provisioning takes approximately 90 seconds even in LocalStack.
> This is expected — plan for it when running apply.

---

## Real AWS deployment

This configuration is designed for real AWS deployment. For a live deployment:

- Omit `provider_override.tf` and `backend_local.hcl` — these are LocalStack-specific
  overrides and should not exist in a real AWS context
- Configure AWS credentials via the AWS CLI or environment variables as normal
- Set `admin_cidr` in `terraform.tfvars` to your actual public IP:
  ```bash
  curl https://checkip.amazonaws.com
  ```
- Initialize and apply without the backend override:
  ```bash
  terraform init
  terraform apply
  ```

> **Cost warning:** A NAT Gateway costs approximately $0.045/hour plus $0.045/GB of data
> processed. It is not covered by the AWS free tier. Run `terraform destroy` when the
> environment is not in use.

---

## Project structure

```
modern-terraform/
├── bootstrap/
│   ├── main.tf               # S3 state bucket with versioning, encryption, access block
│   └── .terraform.lock.hcl
├── modules/
│   ├── networking/
│   │   ├── main.tf           # VPC, subnets, IGW, NAT, route tables, security groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       ├── main.tf           # AMI data source + EC2 instances via for_each
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                   # Provider configuration and module calls
├── backend.tf                # S3 remote backend with use_lockfile
├── variables.tf              # All input variables
├── terraform.tfvars.example  # Template for required variable values
└── .terraform.lock.hcl       # Provider version lock
```

Gitignored (never committed): `terraform.tfvars`, `backend_local.hcl`,
`provider_override.tf`, `.terraform/`

---

## What this configuration provisions

**Bootstrap** (run once, separate local state):
- 1 S3 bucket (`epe-mt-terraform-state-01`) with versioning enabled, AES256
  server-side encryption, and full public access block

**Main configuration** (remote state in the above bucket):
- 1 VPC (`10.0.0.0/16`)
- 2 public subnets (`10.0.1.0/24`, `10.0.2.0/24`) across `us-east-1a` and `us-east-1b`
- 2 private subnets (`10.0.101.0/24`, `10.0.102.0/24`) across `us-east-1a` and `us-east-1b`
- 1 Internet Gateway + public route table + 2 route table associations
- 1 Elastic IP + 1 NAT Gateway (in first public subnet) + private route table +
  2 route table associations
- 2 security groups: bastion (SSH from `admin_cidr` only) and private compute
  (SSH from bastion SG only)
- 5 EC2 instances (Amazon Linux 2023, t3.micro) in the first private subnet, keyed by
  purpose: `source-control`, `artifact-repo`, `directory-services`, `ci-cd`, `monitoring`

---

## Notes on sensitive data

This is a demonstration configuration. No real AWS account IDs, AMI IDs, subnet IDs, or
credentials appear anywhere in the committed files. The `admin_cidr` variable uses an
intentionally invalid placeholder default (`"YOUR_IP_HERE/32"`) that causes a plan-time
failure rather than silently defaulting to an open CIDR. The files `terraform.tfvars`,
`backend_local.hcl`, and `provider_override.tf` are gitignored and are never committed.
