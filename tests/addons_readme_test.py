#!/usr/bin/env python3
"""Documentation checks for the addons Helm modules."""

from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
MODULES_DIR = REPO_ROOT / "infra" / "modules" / "addons"

REQUIRED_SECTIONS = (
    "## Inputs",
    "## Outputs",
    "## Example Usage",
    "## Dependency Notes",
)

MODULES = (
    "ingress-nginx",
    "externaldns",
    "cert-manager",
    "argocd-bootstrap",
)


def main() -> int:
    issues: list[str] = []
    for module in MODULES:
        readme = MODULES_DIR / module / "README.md"
        if not readme.exists():
            issues.append(f"{readme} not found")
            continue
        content = readme.read_text()
        missing = [section for section in REQUIRED_SECTIONS if section not in content]
        if missing:
            issues.append(f"{readme} missing {', '.join(missing)}")
    if issues:
        sys.stderr.write("addons README checks failed:\n")
        sys.stderr.write("\n".join(f"- {issue}" for issue in issues) + "\n")
        return 1
    print("addons READMEs contain required documentation sections")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
