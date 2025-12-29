variables {
  region                     = "ap-southeast-1"
  profile                    = "bootstrap-test"
  bucket_name                = "ali-infra-bootstrap-test"
  table_store_instance_name  = "aliinfra-test-lock"
  lock_table_name            = "terraform_state_lock"
  table_store_description    = "Test lock instance"
  table_store_instance_type  = "Capacity"
  table_store_access_mode    = "Any"
}

run "plan_remote_state" {
  command = plan

  assert {
    condition     = alicloud_oss_bucket.remote_state.acl == "private"
    error_message = "OSS bucket must enforce private ACL"
  }

  assert {
    condition     = alicloud_oss_bucket.remote_state.server_side_encryption_rule[0].sse_algorithm == "AES256"
    error_message = "OSS bucket must use AES256 SSE"
  }

  assert {
    condition     = alicloud_oss_bucket.remote_state.versioning[0].status == "Enabled"
    error_message = "OSS bucket versioning must be Enabled"
  }

  assert {
    condition     = alicloud_ots_table.state_lock.primary_key[0].name == "LockID" && alicloud_ots_table.state_lock.primary_key[0].type == "STRING"
    error_message = "TableStore table must use LockID string primary key"
  }

  assert {
    condition     = output.remote_state_bucket == var.bucket_name
    error_message = "remote_state_bucket output must return the requested bucket name"
  }

  assert {
    condition     = output.lock_table_name == var.lock_table_name
    error_message = "lock_table_name output must expose the configured table name"
  }

  assert {
    condition     = output.tablestore_endpoint == format("https://%s.%s.ots.aliyuncs.com", var.table_store_instance_name, var.region)
    error_message = "tablestore_endpoint output must follow the standard https://<instance>.<region>.ots.aliyuncs.com format"
  }
}
