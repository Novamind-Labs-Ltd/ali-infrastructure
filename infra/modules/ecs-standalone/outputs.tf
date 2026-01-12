# -----------------------------------------------------------------------------
# ECS Standalone Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Instance Outputs
# -----------------------------------------------------------------------------

output "instance_id" {
  description = "ECS instance ID"
  value       = alicloud_instance.this.id
}

output "public_ip" {
  description = "Public IP address (if allocated)"
  value       = alicloud_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = alicloud_instance.this.private_ip
}

output "ssh_command" {
  description = "SSH connection command"
  value       = "ssh ubuntu@${alicloud_instance.this.public_ip}"
}

output "auto_release_time" {
  description = "Planned auto-release time (UTC)"
  value       = local.auto_release_time
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = alicloud_vpc.this.id
}

output "vswitch_id" {
  description = "vSwitch ID"
  value       = alicloud_vswitch.this.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = alicloud_security_group.this.id
}

# -----------------------------------------------------------------------------
# Key Pair Output
# -----------------------------------------------------------------------------

output "key_pair_name" {
  description = "SSH Key Pair name"
  value       = alicloud_key_pair.this.key_pair_name
}
