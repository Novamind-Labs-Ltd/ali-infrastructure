#!/usr/bin/env bash
# Usage: source scripts/export-aliyun-profile.sh <profile>
# When sourced, this exports ALICLOUD_* variables for Terraform/OSS backends.
profile="${1:-}"
if [[ -z "$profile" ]]; then
  echo "usage: source scripts/export-aliyun-profile.sh <profile-name>" >&2
  return 1 2>/dev/null || exit 1
fi
config_file="$HOME/.aliyun/config.json"
if [[ ! -f "$config_file" ]]; then
  echo "ALIYUN config not found at $config_file" >&2
  return 1 2>/dev/null || exit 1
fi
exports=$(python3 - "$profile" "$config_file" <<'PY'
import json, os, sys
profile, config_path = sys.argv[1], sys.argv[2]
conf = json.load(open(config_path))
for entry in conf.get("profiles", []):
    if entry.get("name") == profile:
        missing = [k for k in ("access_key_id","access_key_secret","sts_token") if not entry.get(k)]
        if missing:
            raise SystemExit(f"Profile '{profile}' missing fields: {', '.join(missing)}")
        print(f'export ALICLOUD_ACCESS_KEY="{entry["access_key_id"]}"')
        print(f'export ALICLOUD_SECRET_KEY="{entry["access_key_secret"]}"')
        print(f'export ALICLOUD_SECURITY_TOKEN="{entry["sts_token"]}"')
        print(f'export ALICLOUD_PROFILE="{profile}"')
        break
else:
    raise SystemExit(f"Profile '{profile}' not found in ~/.aliyun/config.json")
PY
) || {
  echo "Failed to read credentials for profile $profile" >&2
  return 1 2>/dev/null || exit 1
}
eval "$exports"
unset exports
echo "Exported Aliyun STS credentials for profile '$profile'."
