#!/usr/bin/env python3
"""Structural checks for the foundation-network Terraform module."""

from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
MODULE_DIR = REPO_ROOT / "infra" / "modules" / "foundation-network"

MAIN_TF = MODULE_DIR / "main.tf"
VARIABLES_TF = MODULE_DIR / "variables.tf"
OUTPUTS_TF = MODULE_DIR / "outputs.tf"

MAIN_PATTERNS = {
    "required_providers_alicloud": re.compile(
        r'required_providers\s*{\s*alicloud\s*=\s*{\s*source\s*=\s*"aliyun/alicloud"\s*version\s*=\s*">=\s*1\.200\.0"\s*}',
        re.MULTILINE,
    ),
    "vpc_resource": re.compile(r'resource\s+"alicloud_vpc"\s+"', re.MULTILINE),
    "public_subnets": re.compile(r'resource\s+"alicloud_vswitch"\s+"network_public_vswitch"', re.MULTILINE),
    "private_subnets": re.compile(r'resource\s+"alicloud_vswitch"\s+"network_private_vswitch"', re.MULTILINE),
    "nat_gateway": re.compile(r'resource\s+"alicloud_nat_gateway"\s+"', re.MULTILINE),
    "security_group": re.compile(r'resource\s+"alicloud_security_group"\s+"', re.MULTILINE),
}

VARIABLES = (
    "vpc_cidr",
    "public_subnet_cidrs",
    "private_subnet_cidrs",
    "zones",
    "tags",
    "name_prefix",
)

OUTPUTS = (
    "vpc_id",
    "vpc_name",
    "public_subnet_ids",
    "public_subnet_names",
    "private_subnet_ids",
    "private_subnet_names",
    "nat_gateway_id",
    "nat_gateway_name",
    "security_group_ids",
    "security_group_names",
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
        sys.stderr.write("Foundation network module checks failed:\n")
        sys.stderr.write("\n".join(f"- {issue}" for issue in issues) + "\n")
        return 1
    print("foundation-network module defines required resources, variables, and outputs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
