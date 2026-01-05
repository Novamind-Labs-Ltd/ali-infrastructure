output "vpc_id" {
  value       = alicloud_vpc.this.id
  description = "VPC ID"
}

output "vswitch_id" {
  value       = alicloud_vswitch.this.id
  description = "vSwitch ID"
}

output "security_group_id" {
  value       = alicloud_security_group.this.id
  description = "Security Group ID"
}

