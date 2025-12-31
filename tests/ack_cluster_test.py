#!/usr/bin/env python3
"""Structural checks for the ack-cluster Terraform module."""

from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
MODULE_DIR = REPO_ROOT / "infra" / "modules" / "ack-cluster"

MAIN_TF = MODULE_DIR / "main.tf"
VARIABLES_TF = MODULE_DIR / "variables.tf"
OUTPUTS_TF = MODULE_DIR / "outputs.tf"

MAIN_PATTERNS = {
    "required_providers_alicloud": re.compile(
        r'required_providers\s*{\s*alicloud\s*=\s*{\s*source\s*=\s*"aliyun/alicloud"\s*version\s*=\s*">=\s*1\.200\.0"\s*}',
        re.MULTILINE,
    ),
    "ack_cluster_resource": re.compile(
        r'resource\s+"alicloud_cs_managed_kubernetes"\s+"ack_cluster"', re.MULTILINE
    ),
    "ack_node_pool_resource": re.compile(
        r'resource\s+"alicloud_cs_kubernetes_node_pool"\s+"ack_node_pool"', re.MULTILINE
    ),
    "oidc_enabled": re.compile(r"enable_rrsa\s*=\s*true", re.MULTILINE),
}

VARIABLES = (
    "name_prefix",
    "vpc_id",
    "vswitch_ids",
    "node_pool_vswitch_ids",
    "node_pool_instance_types",
    "node_pool_desired_size",
    "kubeconfig_path",
    "tags",
)

OUTPUTS = (
    "cluster_id",
    "cluster_name",
    "api_endpoint",
    "kubeconfig_raw",
    "kubeconfig_path",
    "oidc_issuer_url",
    "node_pool_ids",
)

def check_main() -> list[str]:
    if not MAIN_TF.exists():
        return [f"{MAIN_TF} not found"]
    content = MAIN_TF.read_text()
    missing = [name for name, pattern in MAIN_PATTERNS.items() if not pattern.search(content)]
    return [f"main.tf missing {name}" for name in missing]


def check_variables() -> list[str]:
    if not VARIABLES_TF.exists():
        return [f"{VARIABLES_TF} not found"]
    content = VARIABLES_TF.read_text()
    missing = [name for name in VARIABLES if f'variable "{name}"' not in content]
    return [f"variables.tf missing variable {name}" for name in missing]

def check_outputs() -> list[str]:
    if not OUTPUTS_TF.exists():
        return [f"{OUTPUTS_TF} not found"]
    content = OUTPUTS_TF.read_text()
    missing = [name for name in OUTPUTS if f'output "{name}"' not in content]
    return [f"outputs.tf missing output {name}" for name in missing]


def main() -> int:
    issues = check_main() + check_variables() + check_outputs()
    if issues:
        sys.stderr.write("ack-cluster module checks failed:\n")
        sys.stderr.write("\n".join(f"- {issue}" for issue in issues) + "\n")
        return 1
    print("ack-cluster module defines required resources, variables, and outputs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
