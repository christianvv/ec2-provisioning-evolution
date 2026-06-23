# EC2 Provisioning Evolution

A portfolio repository documenting the evolution of AWS EC2 instance provisioning
across two distinct eras of infrastructure tooling — from SaltStack's salt-cloud
module in the mid-2010s to modern Terraform-based declarative infrastructure.

---

## Repository structure

```
ec2-provisioning-evolution/
├── legacy-salt-cloud/               ← Part 1
│   ├── README.md
│   ├── cloud.providers.d/
│   │   └── ec2-provider.conf        # AWS EC2 provider, instance role auth
│   ├── cloud.profiles.d/
│   │   └── devops-tooling-profile.conf  # CentOS 7 profiles, AZ variants, size matrix
│   ├── cloud.maps.d/
│   │   └── devops-tooling-map.conf  # Named instances → profiles
│   └── bootstrap-scripts/
│       └── bootstrap-minion.sh      # Salt minion install + master handoff
└── modern-terraform/                ← Part 2 (coming soon)
```

---

## Part 1 — Legacy: salt-cloud (circa 2016–2018)

Located in [`legacy-salt-cloud/`](legacy-salt-cloud/).

A recreation of the SaltStack salt-cloud-based provisioning system originally
architected and built for a private-subnet DevOps tooling environment on AWS.
The environment provisioned a small fleet of purpose-built servers — source
control, artifact repository, directory services, CI/CD, and monitoring — all
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

## Part 2 — Modern: Terraform (coming soon)

The `modern-terraform/` directory is planned for a future addition. It will
rebuild the same provisioning goal using Terraform, illustrating the shift in
approach — declarative HCL, explicit resource dependency graphs, remote state,
and a provider/module ecosystem that didn't exist in the salt-cloud era.

---

## Repository notes

All configuration values in this repository are illustrative. Any AMI IDs,
subnet IDs, security group IDs, account IDs, IP addresses, and key names are
generic placeholders marked clearly in comments. No production credentials or
environment-specific identifiers are included.
