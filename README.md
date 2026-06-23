# EC2 Provisioning Evolution

A portfolio repository documenting the evolution of AWS EC2 instance provisioning
across two distinct eras of infrastructure tooling.

---

## Part 1 — Legacy: salt-cloud (circa 2016–2018)

Located in [`legacy-salt-cloud/`](legacy-salt-cloud/).

A recreation of the SaltStack salt-cloud-based provisioning system originally
architected and built for a private-subnet DevOps tooling environment on AWS.
Covers the provider configuration, CentOS 7 instance profiles, deployment maps,
and a custom bootstrap script that installs the Salt minion and hands off to
Salt state management.

See [`legacy-salt-cloud/README.md`](legacy-salt-cloud/README.md) for the full
design walkthrough.

---

## Part 2 — Modern: Terraform (coming soon)

The `modern-terraform/` directory is planned for a future addition. It will
rebuild the same provisioning goal using Terraform, illustrating the shift in
approach — declarative HCL state management, explicit resource dependencies,
remote state, and a provider/module ecosystem that didn't exist in the salt-cloud
era.

---

## Repository notes

All configuration values in this repository are illustrative. Any AMI IDs,
subnet IDs, security group IDs, account IDs, IP addresses, and key names are
generic placeholders marked clearly in comments. No production credentials or
environment-specific identifiers are included.
