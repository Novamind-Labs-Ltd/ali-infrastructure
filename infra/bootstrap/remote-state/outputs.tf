output "remote_state_bucket" {
  description = "Name of the OSS bucket that stores Terraform state."
  value       = alicloud_oss_bucket.remote_state.bucket
}

output "tablestore_instance_name" {
  description = "Name of the TableStore instance backing Terraform state locks."
  value       = alicloud_ots_instance.remote_state.name
}

output "lock_table_name" {
  description = "TableStore table used for Terraform state locking."
  value       = alicloud_ots_table.state_lock.table_name
}

output "tablestore_endpoint" {
  description = "Public HTTPS endpoint for the TableStore instance (used in backend.hcl)."
  value       = format("https://%s.%s.ots.aliyuncs.com", alicloud_ots_instance.remote_state.name, var.region)
}
