terraform {
  required_version = ">= 1.3"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.224.0" # Required for alicloud_oss_bucket_public_access_block
    }
  }
}

# -----------------------------------------------------------------------------
# OSS Bucket (with optional lifecycle rules)
# -----------------------------------------------------------------------------

resource "alicloud_oss_bucket" "this" {
  bucket        = "${var.name_prefix}-images-${var.environment}"
  storage_class = var.storage_class
  force_destroy = var.force_destroy
  tags          = var.tags

  # Lifecycle rules (inline)
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      id      = lifecycle_rule.value.id
      prefix  = lifecycle_rule.value.prefix
      enabled = lifecycle_rule.value.enabled

      dynamic "expiration" {
        for_each = lifecycle_rule.value.expiration_days != null ? [1] : []
        content {
          days = lifecycle_rule.value.expiration_days
        }
      }

      dynamic "transitions" {
        for_each = lifecycle_rule.value.transition_days != null ? [1] : []
        content {
          days          = lifecycle_rule.value.transition_days
          storage_class = lifecycle_rule.value.transition_storage_class
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Public Access Block (disable when public ACL is needed)
# -----------------------------------------------------------------------------
# Must be disabled BEFORE setting public ACL

resource "alicloud_oss_bucket_public_access_block" "this" {
  count               = var.acl != "private" ? 1 : 0
  bucket              = alicloud_oss_bucket.this.bucket
  block_public_access = false
}

# -----------------------------------------------------------------------------
# Bucket ACL (separate resource - v1.220.0+)
# -----------------------------------------------------------------------------

resource "alicloud_oss_bucket_acl" "this" {
  bucket = alicloud_oss_bucket.this.bucket
  acl    = var.acl

  depends_on = [alicloud_oss_bucket_public_access_block.this]
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

resource "alicloud_oss_bucket_cors" "this" {
  count         = var.enable_cors ? 1 : 0
  bucket        = alicloud_oss_bucket.this.bucket
  response_vary = true

  depends_on = [alicloud_oss_bucket_acl.this]

  cors_rule {
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    allowed_headers = var.cors_allowed_headers
    expose_header   = toset(var.cors_expose_headers)
    max_age_seconds = var.cors_max_age_seconds
  }
}

# -----------------------------------------------------------------------------
# RAM User for Imgix Access (optional)
# -----------------------------------------------------------------------------

resource "alicloud_ram_user" "imgix" {
  count        = var.create_ram_user ? 1 : 0
  name         = var.ram_user_name
  display_name = "Imgix OSS Reader"
  comments     = "Service account for Imgix to read images from OSS bucket: ${alicloud_oss_bucket.this.bucket}"
  force        = true # Allow clean teardown by removing all relationships
}

resource "alicloud_ram_policy" "imgix_oss_read" {
  count       = var.create_ram_user ? 1 : 0
  policy_name = "${var.name_prefix}-imgix-oss-read-${var.environment}"
  policy_document = jsonencode({
    Version = "1"
    Statement = [
      {
        Effect = "Allow"
        Action = ["oss:GetObject", "oss:ListObjects"]
        Resource = [
          "acs:oss:*:*:${alicloud_oss_bucket.this.bucket}",
          "acs:oss:*:*:${alicloud_oss_bucket.this.bucket}/*"
        ]
      }
    ]
  })
  description     = "Read-only access to ${alicloud_oss_bucket.this.bucket} for Imgix"
  rotate_strategy = "DeleteOldestNonDefaultVersionWhenLimitExceeded"
}

resource "alicloud_ram_user_policy_attachment" "imgix" {
  count       = var.create_ram_user ? 1 : 0
  policy_name = alicloud_ram_policy.imgix_oss_read[0].policy_name
  policy_type = "Custom"
  user_name   = alicloud_ram_user.imgix[0].name
}
