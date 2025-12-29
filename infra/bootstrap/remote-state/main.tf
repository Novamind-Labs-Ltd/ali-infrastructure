terraform {
  required_version = ">= 1.5.0"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.200.0"
    }
  }
}

provider "alicloud" {
  region  = var.region
  profile = var.profile
}

resource "alicloud_oss_bucket" "remote_state" {
  bucket = var.bucket_name

  versioning {
    status = "Enabled"
  }

  server_side_encryption_rule {
    sse_algorithm = "AES256"
  }

  tags = var.tags
}

resource "alicloud_oss_bucket_acl" "remote_state" {
  bucket = alicloud_oss_bucket.remote_state.bucket
  acl    = "private"
}

resource "alicloud_ots_instance" "remote_state" {
  name        = var.table_store_instance_name
  description = var.table_store_description

  instance_type = var.table_store_instance_type
  accessed_by   = var.table_store_access_mode

  tags = var.tags
}

resource "alicloud_ots_table" "state_lock" {
  instance_name = alicloud_ots_instance.remote_state.name
  table_name    = var.lock_table_name

  time_to_live                  = -1
  max_version                   = 1
  deviation_cell_version_in_sec = 86400

  primary_key {
    name = "LockID"
    type = "String"
  }

  # Reserved throughput defaults to pay-as-you-go (0 read/write units) in provider;
  # no schema attributes exist, so we rely on the API default to avoid idle capacity.
}
