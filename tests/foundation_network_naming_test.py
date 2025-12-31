#!/usr/bin/env python3
"""Naming convention checks for the foundation-network Terraform module."""

from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
MAIN_TF = REPO_ROOT / "infra" / "modules" / "foundation-network" / "main.tf"

RESOURCE_PATTERN = re.compile(r'resource\s+"[^"]+"\s+"(?P<name>[^"]+)"')


def main() -> int:
    if not MAIN_TF.exists():
        sys.stderr.write(f"{MAIN_TF} not found\n")
        return 1
    content = MAIN_TF.read_text()
    resource_names = RESOURCE_PATTERN.findall(content)
    if not resource_names:
        sys.stderr.write("No Terraform resources found in main.tf\n")
        return 1
    invalid = [name for name in resource_names if not name.startswith("network_")]
    if invalid:
        sys.stderr.write("Resources must use network_ prefix:\n")
        sys.stderr.write("\n".join(f"- {name}" for name in invalid) + "\n")
        return 1
    print("foundation-network resources follow naming conventions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
