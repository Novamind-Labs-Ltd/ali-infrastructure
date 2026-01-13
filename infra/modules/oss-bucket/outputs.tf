# -----------------------------------------------------------------------------
# Bucket Outputs
# -----------------------------------------------------------------------------

output "bucket_name" {
  description = "Name of the OSS bucket."
  value       = alicloud_oss_bucket.this.bucket
}

output "bucket_id" {
  description = "ID of the OSS bucket."
  value       = alicloud_oss_bucket.this.id
}

output "bucket_acl" {
  description = "ACL of the OSS bucket."
  value       = alicloud_oss_bucket_acl.this.acl
}

output "bucket_endpoint" {
  description = "Public endpoint for the OSS bucket."
  value       = "https://${alicloud_oss_bucket.this.bucket}.oss-${var.region}.aliyuncs.com"
}

output "bucket_internal_endpoint" {
  description = "Internal endpoint for the OSS bucket (use within Alibaba Cloud)."
  value       = "https://${alicloud_oss_bucket.this.bucket}.oss-${var.region}-internal.aliyuncs.com"
}

# -----------------------------------------------------------------------------
# Imgix Configuration Outputs
# -----------------------------------------------------------------------------

output "imgix_s3_endpoint" {
  description = "S3-compatible endpoint for Imgix configuration."
  value       = "oss-${var.region}.aliyuncs.com"
}

output "imgix_web_folder_url" {
  description = "Base URL for Imgix Web Folder source (fallback for public bucket)."
  value       = "https://${alicloud_oss_bucket.this.bucket}.oss-${var.region}.aliyuncs.com"
}

# -----------------------------------------------------------------------------
# RAM User Outputs
# -----------------------------------------------------------------------------

output "ram_user_name" {
  description = "Name of the RAM user created for Imgix. Create access key manually via CLI or Console."
  value       = var.create_ram_user ? alicloud_ram_user.imgix[0].name : null
}

output "ram_policy_name" {
  description = "Name of the RAM policy attached to the Imgix user."
  value       = var.create_ram_user ? alicloud_ram_policy.imgix_oss_read[0].policy_name : null
}
