#!/usr/bin/env python3
"""Documentation checks for the foundation-network Terraform module."""

from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
README = REPO_ROOT / "infra" / "modules" / "foundation-network" / "README.md"

REQUIRED_SECTIONS = (
    "## Inputs",
    "## Outputs",
    "## Example Usage",
    "## Dependency Notes",
)


def main() -> int:
    if not README.exists():
        sys.stderr.write(f"{README} not found\n")
        return 1
    content = README.read_text()
    missing = [section for section in REQUIRED_SECTIONS if section not in content]
    if missing:
        sys.stderr.write("README missing required sections:\n")
        sys.stderr.write("\n".join(f"- {section}" for section in missing) + "\n")
        return 1
    print("foundation-network README contains required documentation sections")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
