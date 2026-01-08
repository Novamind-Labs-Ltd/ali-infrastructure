provider "alicloud" {
  region = var.region
}

locals {
  # Compute max hours based on budget; clamp to auto_release_hours
  budget_hours       = floor(var.budget_usd / var.estimated_hourly_cost_usd)
  effective_hours    = var.auto_release_hours < local.budget_hours ? var.auto_release_hours : local.budget_hours
  instance_user      = "ubuntu" # default for Ubuntu images
  # Aliyun expects AutoReleaseTime as UTC timestamp ending with Z (no offset).
  auto_release_time_utc = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", time_offset.release.rfc3339)
}

# Choose a zone compatible with the instance type
data "alicloud_zones" "this" {
  available_instance_type = var.instance_type
}

resource "alicloud_vpc" "this" {
  cidr_block = var.vpc_cidr
  vpc_name   = "${var.instance_name}-vpc"
  tags       = var.tags
}

resource "alicloud_vswitch" "this" {
  vpc_id            = alicloud_vpc.this.id
  cidr_block        = var.vswitch_cidr
  zone_id           = data.alicloud_zones.this.zones[0].id
  vswitch_name      = "${var.instance_name}-vsw"
  tags              = var.tags
}

resource "alicloud_security_group" "this" {
  security_group_name = "${var.instance_name}-sg"
  description = "Security group for invoice runner"
  vpc_id      = alicloud_vpc.this.id
  tags        = var.tags
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

# SSH key
resource "alicloud_key_pair" "this" {
  key_pair_name = "${var.instance_name}-key"
  public_key = var.ssh_public_key
  tags       = var.tags
}

# Pick an Ubuntu image if not provided
data "alicloud_images" "ubuntu" {
  most_recent = true
  owners      = "system"
  name_regex  = "^ubuntu_22.*x64.*alibase.*"
  instance_type = var.instance_type
  architecture  = "x86_64"
  os_type       = "linux"
  status        = "Available"
}

resource "time_offset" "release" {
  offset_hours = local.effective_hours
}

resource "alicloud_instance" "this" {
  instance_name              = var.instance_name
  instance_type              = var.instance_type
  image_id                   = var.image_id != "" ? var.image_id : data.alicloud_images.ubuntu.images[0].id
  security_groups            = [alicloud_security_group.this.id]
  vswitch_id                 = alicloud_vswitch.this.id

  # Assign a public IP by specifying outbound bandwidth
  internet_max_bandwidth_out = var.internet_max_bandwidth_out

  # Provider currently doesn't accept key_pair_name for alicloud_instance; use deprecated key_name for now
  key_name = alicloud_key_pair.this.key_pair_name

  system_disk_category = var.system_disk_category
  # Let ECS default to the image size to avoid size mismatch errors.
  # system_disk_size     = var.system_disk_size
  system_disk_performance_level = var.system_disk_performance_level

  # Auto release time (UTC RFC3339). Use Z suffix to satisfy API format.
  auto_release_time = local.auto_release_time_utc

  # Cloud-init
  user_data = file("${path.module}/user_data.sh")

  tags = var.tags
}

output "instance_id" {
  value       = alicloud_instance.this.id
  description = "ECS instance ID"
}

output "public_ip" {
  value       = alicloud_instance.this.public_ip
  description = "Public IP (if allocated)"
}

output "private_ip" {
  value       = alicloud_instance.this.private_ip
  description = "Private IP"
}

output "auto_release_time" {
  value       = local.auto_release_time_utc
  description = "Planned auto release time (UTC)"
}

output "ssh_command" {
  value       = "ssh ${local.instance_user}@${alicloud_instance.this.public_ip}"
  description = "Convenience SSH command"
}
