# -----------------------------------------------------------------------------
# Root Terragrunt Configuration
# -----------------------------------------------------------------------------
# This is the root configuration inherited by all child terragrunt.hcl files.
# It configures:
#   - Remote state in Alibaba Cloud OSS with TableStore locking
#   - Common inputs passed to all modules
#   - Validation hooks for quality gates
#
# Note: Provider configuration is handled by each module, not generated here,
# since modules already have their own terraform blocks with required_providers.
# -----------------------------------------------------------------------------

locals {
  # Parse the path to extract environment from directory structure
  # Expected path: live/{env}/{component}/terragrunt.hcl
  # After path_relative_to_include: {env}/{component}
  path_parts  = split("/", path_relative_to_include())
  environment = try(local.path_parts[0], "unknown")

  # Load environment-specific variables if env.hcl exists
  env_vars = try(
    read_terragrunt_config(find_in_parent_folders("env.hcl")),
    { locals = {} }
  )

  # ---------------------------------------------------------------------------
  # Remote State Configuration
  # ---------------------------------------------------------------------------
  # These values can be overridden via:
  #   1. Environment variables (preferred for CI/CD)
  #   2. env.hcl files (per-environment defaults)
  #   3. Fallback defaults below
  # ---------------------------------------------------------------------------
  remote_state_region = coalesce(
    get_env("TG_STATE_REGION", ""),
    try(local.env_vars.locals.remote_state_region, ""),
    "ap-southeast-1"
  )

  remote_state_bucket = coalesce(
    get_env("TG_STATE_BUCKET", ""),
    try(local.env_vars.locals.remote_state_bucket, ""),
    "tfstate-sandbox"
  )

  remote_state_profile = coalesce(
    get_env("ALICLOUD_PROFILE", ""),
    try(local.env_vars.locals.remote_state_profile, ""),
    "novamind-sandbox-kun"
  )

  remote_state_tablestore_table = coalesce(
    get_env("TG_STATE_LOCK_TABLE", ""),
    try(local.env_vars.locals.remote_state_tablestore_table, ""),
    "terraform_state_lock"
  )

  remote_state_tablestore_endpoint = coalesce(
    get_env("TG_STATE_LOCK_ENDPOINT", ""),
    try(local.env_vars.locals.remote_state_tablestore_endpoint, ""),
    "https://tfstate-sandbox.ap-southeast-1.ots.aliyuncs.com"
  )
}

# -----------------------------------------------------------------------------
# Remote State Configuration
# -----------------------------------------------------------------------------
# Automatically generates backend.tf for each module with OSS backend
# State files are organized by: {env}/{component}/terraform.tfstate
# -----------------------------------------------------------------------------
remote_state {
  backend = "oss"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    region              = local.remote_state_region
    bucket              = local.remote_state_bucket
    key                 = "${path_relative_to_include()}/terraform.tfstate"
    profile             = local.remote_state_profile
    tablestore_table    = local.remote_state_tablestore_table
    tablestore_endpoint = local.remote_state_tablestore_endpoint
    encrypt             = true
  }
}

# -----------------------------------------------------------------------------
# Terraform Configuration with Hooks
# -----------------------------------------------------------------------------
# Validation and formatting hooks for quality gates
# -----------------------------------------------------------------------------
terraform {
  # Validate configuration before plan/apply
  before_hook "validate" {
    commands = ["apply", "plan"]
    execute  = ["terraform", "validate"]
  }

  # Auto-format before plan/apply
  before_hook "fmt" {
    commands = ["apply", "plan"]
    execute  = ["terraform", "fmt"]
  }

  # Log successful applies
  after_hook "apply_success" {
    commands     = ["apply"]
    execute      = ["echo", "Successfully applied Terraform changes"]
    run_on_error = false
  }

  # Error notification hook
  error_hook "apply_error" {
    commands  = ["apply", "plan"]
    execute   = ["echo", "ERROR: Terraform operation failed. Check the output above."]
    on_errors = [".*"]
  }
}

# -----------------------------------------------------------------------------
# Provider Version Constraints
# -----------------------------------------------------------------------------
# Generate consistent provider versions across all modules
# -----------------------------------------------------------------------------
generate "provider_versions" {
  path      = "provider_versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.5.0"
    }
  EOF
}

# -----------------------------------------------------------------------------
# Common Inputs
# -----------------------------------------------------------------------------
# These inputs are passed to all modules and can be overridden in child configs.
# Note: Modules must declare these variables in their variables.tf to use them.
# -----------------------------------------------------------------------------
inputs = {
  # Environment is passed to modules that accept it
  environment = local.environment
}
