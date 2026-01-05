Aliyun ECS Invoice Runner (Terraform)
====================================

This Terraform module provisions a secure Alibaba Cloud ECS instance suitable for running the invoice processing agent described in `docs/tech-spec-invoice-processing.md`.

What it creates
- VPC + vSwitch in a zone compatible with the chosen instance type
- Security Group allowing SSH from your CIDR (you must set it)
- SSH Key Pair (from your provided public key)
- ECS instance (`ecs.c9i.large` by default) with Ubuntu image
- Optional public IP via Internet bandwidth
- Auto-release safeguard capped by hours derived from a budget (approximate $ cap)

Prerequisites
- Terraform >= 1.3
- Alibaba Cloud credentials available via env vars or profile
  - `ALICLOUD_ACCESS_KEY`
  - `ALICLOUD_SECRET_KEY`
  - `ALICLOUD_REGION` (or set `region` variable)

Quick start
1) Prepare variables (copy to `terraform.tfvars` or pass with `-var`):

   instance_name       = "invoice-runner"
   ssh_public_key      = "ssh-ed25519 AAAA... you@host"
   allowed_ssh_cidr    = "YOUR.PUBLIC.IP.0/24"   # Set this! Avoid 0.0.0.0/0
   budget_usd          = 100
   estimated_hourly_cost_usd = 0.20               # Adjust to your region pricing

2) Init + apply

   terraform init
   terraform apply

3) Connect

   Use the output `ssh_command` to connect (default user on Ubuntu is `ubuntu`).

About the cost cap
- Exact cost enforcement isn’t available from Terraform. This module approximates a cap by auto-releasing the instance after a number of hours computed as:
  `min(auto_release_hours, floor(budget_usd / estimated_hourly_cost_usd))`.
- Adjust `estimated_hourly_cost_usd` conservatively for your region.
- For stricter guardrails, consider adding CloudMonitor (CMS) billing alarms outside this module.

Notes
- Default image attempts to pick the latest Ubuntu 22.04 x86_64 system image. You can override with `image_id`.
- If you prefer a static EIP, set `internet_max_bandwidth_out = 0` and manage an `alicloud_eip` separately.
- Cloud-init (`user_data.sh`) installs basic packages. Extend it as needed for your agent.

