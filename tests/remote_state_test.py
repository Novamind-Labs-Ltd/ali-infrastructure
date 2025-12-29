#!/usr/bin/env python3
"""Structural checks for the remote-state Terraform module."""

from pathlib import Path
import re
import sys

MODULE_DIR = Path(__file__).resolve().parents[1] / "infra" / "bootstrap" / "remote-state"
MAIN_TF = MODULE_DIR / "main.tf"

REQUIRED_PATTERNS = {
    "bucket_acl_resource": re.compile(
        r'resource\s+"alicloud_oss_bucket_acl"\s+"remote_state"[\s\S]*?acl\s*=\s*"private"',
        re.MULTILINE,
    ),
    "versioning_enabled": re.compile(r'versioning\s*{\s*status\s*=\s*"Enabled"[\s\S]*?}', re.MULTILINE),
    "sse_aes256": re.compile(r'server_side_encryption_rule\s*{[\s\S]*?sse_algorithm\s*=\s*"AES256"[\s\S]*?}', re.MULTILINE),
    "table_primary_key": re.compile(
        r'alicloud_ots_table"\s+"state_lock"[\s\S]*?primary_key\s*{[\s\S]*?name\s*=\s*"LockID"[\s\S]*?type\s*=\s*"String"[\s\S]*?}',
        re.MULTILINE,
    ),
}


def main() -> int:
    if not MAIN_TF.exists():
        sys.stderr.write("main.tf not found")
        return 1
    content = MAIN_TF.read_text()
    missing = [name for name, pattern in REQUIRED_PATTERNS.items() if not pattern.search(content)]
    if missing:
        sys.stderr.write("Missing required configuration sections: " + ", ".join(missing) + "\n")
        return 1
    print("remote-state Terraform module enforces ACL, versioning, SSE, and lock table schema")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
