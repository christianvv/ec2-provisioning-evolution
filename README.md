# EC2 Provisioning Evolution

![SaltStack](https://img.shields.io/badge/SaltStack-2D4A6E?style=flat&logo=saltproject&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=flat&logo=amazonaws&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat)
![Tested with LocalStack](https://img.shields.io/badge/Tested_with-LocalStack-teal?style=flat)

A portfolio repository documenting the evolution of AWS EC2 instance provisioning
across two distinct eras of infrastructure tooling — from SaltStack's salt-cloud
module in the mid-2010s to modern Terraform-based declarative infrastructure.

---

## Repository structure

```
ec2-provisioning-evolution/
├── LICENSE
├── legacy-salt-cloud/               ← Part 1
│   ├── README.md
│   ├── cloud.conf.d/
│   │   └── cloud.conf               # Global defaults: deploy script, logging
│   ├── cloud.providers.d/
│   │   └── ec2-provider.conf        # AWS EC2 provider, instance role auth
│   ├── cloud.profiles.d/
│   │   └── devops-tooling-profile.conf  # CentOS 7 profiles, AZ variants, size matrix
│   ├── cloud.maps.d/
│   │   └── devops-tooling-map.conf  # Named instances → profiles
│   └── bootstrap-scripts/
│       └── bootstrap-minion.sh      # Salt minion install + master handoff
└── modern-terraform/                ← Part 2
    ├── README.md
    ├── bootstrap/
    │   └── main.tf                  # S3 state bucket with versioning and encryption
    ├── modules/
    │   ├── networking/              # VPC, subnets, gateways, route tables, security groups
    │   └── compute/                 # AMI data source, EC2 instances via for_each
    ├── main.tf                      # Provider configuration and module calls
    ├── backend.tf                   # S3 remote backend with native use_lockfile locking
    └── variables.tf                 # Input variables
```

---

## Skills Demonstrated

### Legacy (salt-cloud era)

- salt-cloud provider/profile/map model for declarative EC2 instance provisioning
- IAM instance-role credentials — no static access keys stored on disk
- Multi-AZ profile design using `extends` for a size matrix without configuration duplication
- Bootstrap automation via Jinja-templated deploy scripts with pre-generated RSA minion key
  injection for zero-touch Salt master registration
- Internal S3-hosted yum repository for controlled Salt versioning in a network-restricted VPC
- Private-subnet-only instance placement with no public IP assignment

### Modern (Terraform era)

- Remote S3 backend with native S3 locking (`use_lockfile`) — DynamoDB-based locking
  intentionally avoided as deprecated
- Bootstrap pattern for state backend chicken-and-egg provisioning
- Reusable module design with networking and compute concerns in separate modules
- Public/private VPC tiering with NAT Gateway and bastion security group pattern
- Dynamic AMI lookup via data source — no hardcoded AMI IDs
- `for_each` over a map variable for stable, purpose-keyed resource addressing in state
- `terraform state mv` for zero-infrastructure-impact module refactoring
- LocalStack for cost-free local testing of full apply/destroy lifecycle

---

## Part 1 — Legacy: salt-cloud (circa 2016–2018)

Located in [`legacy-salt-cloud/`](legacy-salt-cloud/).

A recreation of the SaltStack salt-cloud-based provisioning system originally
architected and built for a private-subnet DevOps tooling environment on AWS.
The environment provisioned a small fleet of purpose-built servers — source
control, artifact repository, directory services, GitLab Runner for CI/CD, and monitoring — all
as CentOS 7 instances within private VPC subnets.

The system used salt-cloud's provider/profile/map model: a provider block
handled AWS authentication via instance role credentials, profile blocks defined
the CentOS 7 AMI, storage, subnet placement, and a size matrix via `extends`,
and a map file tied named minion IDs to profiles for single-command environment
provisioning. A custom bootstrap script installed the Salt minion from an
internal S3-hosted yum repository and injected the pre-generated key pair and
minion config, handing off to Salt state management once the minion checked in.

See [`legacy-salt-cloud/README.md`](legacy-salt-cloud/README.md) for the full
design walkthrough, file-by-file decisions, and operational commands.

---

## Part 2 — Modern: Terraform

Located in [`modern-terraform/`](modern-terraform/).

A ground-up rebuild of the same DevOps tooling fleet using Terraform, illustrating
the shift in approach — declarative HCL, explicit resource dependency graphs,
remote state, and a provider/module ecosystem that didn't exist in the salt-cloud
era. Unlike the legacy system, which provisioned only EC2 instances into a
pre-existing VPC, this configuration manages the full networking foundation from
scratch: VPC, subnets, internet and NAT gateways, route tables, and security groups,
in addition to the compute layer.

State is stored remotely in an S3 bucket using Terraform's native `use_lockfile`
mechanism, which replaces the older DynamoDB-based locking pattern. The S3 bucket
itself is provisioned by a separate bootstrap configuration — a pattern that
sidesteps the chicken-and-egg problem of using a Terraform-managed resource as a
backend before any state exists. Networking and compute resources are organized into
separate modules, with the root config wiring them together through module output
references.

All development and testing was done against LocalStack, enabling a full
apply/destroy lifecycle — including NAT Gateway, EC2 instances, and remote state
operations — without incurring AWS costs.

See [`modern-terraform/README.md`](modern-terraform/README.md) for the full
architecture walkthrough, LocalStack setup, and deployment guide.

---

## Repository notes

All configuration values in this repository are illustrative. Any AMI IDs, subnet IDs,
security group IDs, account IDs, IP addresses, and key names are generic placeholders
or intentionally invalid values (such as the `admin_cidr` variable default
`"YOUR_IP_HERE/32"`, which causes a plan-time failure rather than silently defaulting
to something permissive). No production credentials or environment-specific identifiers
are included. Files containing environment-specific values — `terraform.tfvars`,
`backend_local.hcl`, `provider_override.tf` — are gitignored and are not committed.
Local testing uses LocalStack; no real AWS infrastructure was harmed in the making of
this repository.

---

## License

Licensed under MIT — see [LICENSE](LICENSE).
