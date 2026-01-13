# -----------------------------------------------------------------------------
# DNS Public Zone - Dev Environment
# -----------------------------------------------------------------------------
# Provisions AliCloud DNS public zone for domain management.
# After apply, update NS records at your domain registrar.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/infra/modules/dns-public-zone"
}

inputs = {
  domain_name         = local.env.dns_domain_name
  create_domain_group = local.env.dns_create_domain_group
  domain_group_name   = local.env.dns_domain_group_name
  remark              = local.env.dns_remark
  records             = local.env.dns_initial_records
  tags                = local.env.dns_tags
}
