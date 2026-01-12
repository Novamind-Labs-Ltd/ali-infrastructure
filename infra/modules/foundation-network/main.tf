terraform {
  required_version = ">= 1.3"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.200.0"
    }
  }
}

locals {
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    tostring(idx) => {
      cidr = cidr
      zone = var.zones[idx]
    }
  }
  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    tostring(idx) => {
      cidr = cidr
      zone = var.zones[idx]
    }
  }
}

locals {
  public_subnet_keys  = sort(keys(local.public_subnets))
  private_subnet_keys = sort(keys(local.private_subnets))
}

resource "alicloud_vpc" "network_vpc" {
  vpc_name   = "${var.name_prefix}-vpc"
  cidr_block = var.vpc_cidr
  tags       = var.tags
}

resource "alicloud_vswitch" "network_public_vswitch" {
  for_each = local.public_subnets

  vpc_id       = alicloud_vpc.network_vpc.id
  cidr_block   = each.value.cidr
  zone_id      = each.value.zone
  vswitch_name = "${var.name_prefix}-public-${each.key}"
  tags         = var.tags
}

resource "alicloud_vswitch" "network_private_vswitch" {
  for_each = local.private_subnets

  vpc_id       = alicloud_vpc.network_vpc.id
  cidr_block   = each.value.cidr
  zone_id      = each.value.zone
  vswitch_name = "${var.name_prefix}-private-${each.key}"
  tags         = var.tags
}

resource "alicloud_nat_gateway" "network_nat_gateway" {
  vpc_id           = alicloud_vpc.network_vpc.id
  nat_gateway_name = "${var.name_prefix}-nat"
  nat_type         = var.nat_gateway_type
  specification    = var.nat_gateway_type == "Standard" ? var.nat_gateway_spec : null
  vswitch_id       = alicloud_vswitch.network_public_vswitch[local.public_subnet_keys[0]].id
  tags             = var.tags
}

resource "alicloud_eip_address" "network_nat_eip" {
  address_name         = "${var.name_prefix}-nat-eip"
  bandwidth            = var.nat_bandwidth_mbps
  internet_charge_type = "PayByTraffic"
  tags                 = var.tags
}

resource "alicloud_eip_association" "network_nat_eip_assoc" {
  allocation_id = alicloud_eip_address.network_nat_eip.id
  instance_id   = alicloud_nat_gateway.network_nat_gateway.id
}

resource "alicloud_snat_entry" "network_snat_entry" {
  for_each = alicloud_vswitch.network_private_vswitch

  snat_table_id     = alicloud_nat_gateway.network_nat_gateway.snat_table_ids
  source_vswitch_id = each.value.id
  snat_ip           = alicloud_eip_address.network_nat_eip.ip_address
}

resource "alicloud_security_group" "network_default" {
  security_group_name = "${var.name_prefix}-default-sg"
  vpc_id              = alicloud_vpc.network_vpc.id
  description         = "Default security group for foundation networking."
  tags                = var.tags
}
