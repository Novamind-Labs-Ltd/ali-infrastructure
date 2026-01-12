# -----------------------------------------------------------------------------
# Dev - OSS Bucket for Imgix
# -----------------------------------------------------------------------------
# Deploys OSS bucket for image storage with Imgix CDN integration.
# Includes RAM user with read-only access for Imgix S3-compatible source.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/oss-bucket"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# No dependencies - standalone module

inputs = {
  environment = local.env.locals.environment
  name_prefix = local.env.locals.oss_imgix_name_prefix
  region      = local.env.locals.remote_state_region

  # Bucket configuration
  acl           = local.env.locals.oss_imgix_acl
  force_destroy = local.env.locals.oss_imgix_force_destroy

  # CORS for Imgix
  enable_cors          = true
  cors_allowed_methods = ["GET", "HEAD"]
  cors_allowed_origins = local.env.locals.oss_imgix_cors_origins
  cors_allowed_headers = ["*"]

  # RAM user for Imgix S3-compatible access
  create_ram_user = local.env.locals.oss_imgix_create_ram_user
  ram_user_name   = local.env.locals.oss_imgix_ram_user_name

  tags = local.env.locals.oss_imgix_tags
}
