# -----------------------------------------------------------------------------
# ECS Standalone Module
# -----------------------------------------------------------------------------
# Creates an isolated ECS instance with its own VPC, vSwitch, and Security Group.
# Useful for batch jobs, dev VMs, or standalone workloads.
#
# Features:
#   - Isolated VPC + vSwitch + Security Group
#   - Configurable SSH access (CIDR whitelist)
#   - Auto-release time for cost control
#   - Optional user_data (cloud-init) script
#   - Latest Ubuntu 22.04 by default
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.215.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------

locals {
  # Compute max hours based on budget; clamp to auto_release_hours
  budget_hours      = floor(var.budget_usd / var.estimated_hourly_cost_usd)
  effective_hours   = min(var.auto_release_hours, local.budget_hours)

  # Aliyun expects AutoReleaseTime as UTC timestamp ending with Z
  auto_release_time = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", time_offset.release.rfc3339)

  # Handle user_data: content directly OR file path
  user_data_content = var.user_data_file != "" ? file(var.user_data_file) : var.user_data
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# Choose a zone compatible with the instance type (only when zone_id not provided)
data "alicloud_zones" "this" {
  count                   = var.zone_id == "" ? 1 : 0
  available_instance_type = var.instance_type
}

# Latest Ubuntu 22.04 image (only when image_id not provided)
data "alicloud_images" "ubuntu" {
  count         = var.image_id == "" ? 1 : 0
  most_recent   = true
  owners        = "system"
  name_regex    = "^ubuntu_22.*x64.*alibase.*"
  instance_type = var.instance_type
  architecture  = "x86_64"
  os_type       = "linux"
  status        = "Available"
}

locals {
  # Use provided zone_id or lookup from data source
  zone_id = var.zone_id != "" ? var.zone_id : data.alicloud_zones.this[0].zones[0].id
}

# -----------------------------------------------------------------------------
# VPC Resources
# -----------------------------------------------------------------------------

resource "alicloud_vpc" "this" {
  cidr_block = var.vpc_cidr
  vpc_name   = "${var.name_prefix}-vpc"
  tags       = var.tags
}

resource "alicloud_vswitch" "this" {
  vpc_id       = alicloud_vpc.this.id
  cidr_block   = var.vswitch_cidr
  zone_id      = local.zone_id
  vswitch_name = "${var.name_prefix}-vsw"
  tags         = var.tags
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "alicloud_security_group" "this" {
  security_group_name = "${var.name_prefix}-sg"
  description         = "Security group for ${var.name_prefix}"
  vpc_id              = alicloud_vpc.this.id
  tags                = var.tags
}

resource "alicloud_security_group_rule" "ssh_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.this.id
  cidr_ip           = var.allowed_ssh_cidr
}

resource "alicloud_security_group_rule" "all_out" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 100
  security_group_id = alicloud_security_group.this.id
  cidr_ip           = "0.0.0.0/0"
}

# -----------------------------------------------------------------------------
# SSH Key Pair
# -----------------------------------------------------------------------------

resource "alicloud_key_pair" "this" {
  key_pair_name = "${var.name_prefix}-key"
  public_key    = var.ssh_public_key
  tags          = var.tags
}

# -----------------------------------------------------------------------------
# Auto-Release Timer
# -----------------------------------------------------------------------------

resource "time_offset" "release" {
  offset_hours = local.effective_hours
}

# -----------------------------------------------------------------------------
# ECS Instance
# -----------------------------------------------------------------------------

resource "alicloud_instance" "this" {
  instance_name              = var.name_prefix
  instance_type              = var.instance_type
  image_id                   = var.image_id != "" ? var.image_id : data.alicloud_images.ubuntu[0].images[0].id
  security_groups            = [alicloud_security_group.this.id]
  vswitch_id                 = alicloud_vswitch.this.id
  internet_max_bandwidth_out = var.internet_max_bandwidth_out
  key_name                   = alicloud_key_pair.this.key_pair_name
  system_disk_category       = var.system_disk_category
  system_disk_performance_level = var.system_disk_performance_level
  auto_release_time          = local.auto_release_time
  user_data                  = local.user_data_content != "" ? local.user_data_content : null
  tags                       = var.tags
}
