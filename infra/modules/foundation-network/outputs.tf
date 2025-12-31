output "vpc_id" {
  description = "ID of the VPC."
  value       = alicloud_vpc.network_vpc.id
}

output "vpc_name" {
  description = "Name of the VPC."
  value       = alicloud_vpc.network_vpc.vpc_name
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for key in local.public_subnet_keys : alicloud_vswitch.network_public_vswitch[key].id]
}

output "public_subnet_names" {
  description = "Names of the public subnets."
  value       = [for key in local.public_subnet_keys : alicloud_vswitch.network_public_vswitch[key].vswitch_name]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = [for key in local.private_subnet_keys : alicloud_vswitch.network_private_vswitch[key].id]
}

output "private_subnet_names" {
  description = "Names of the private subnets."
  value       = [for key in local.private_subnet_keys : alicloud_vswitch.network_private_vswitch[key].vswitch_name]
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway."
  value       = alicloud_nat_gateway.network_nat_gateway.id
}

output "nat_gateway_name" {
  description = "Name of the NAT gateway."
  value       = alicloud_nat_gateway.network_nat_gateway.nat_gateway_name
}

output "security_group_ids" {
  description = "IDs of the security groups created for the VPC."
  value       = [alicloud_security_group.network_default.id]
}

output "security_group_names" {
  description = "Names of the security groups created for the VPC."
  value       = [alicloud_security_group.network_default.security_group_name]
}
