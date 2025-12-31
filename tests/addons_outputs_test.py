#!/usr/bin/env python3
"""Output checks for the addons Helm modules."""

from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
MODULES_DIR = REPO_ROOT / "infra" / "modules" / "addons"

MODULE_OUTPUTS = {
    "ingress-nginx": (
        "release_name",
        "release_namespace",
        "release_status",
        "ingress_hostname",
    ),
    "externaldns": (
        "release_name",
        "release_namespace",
        "release_status",
        "dns_zone",
    ),
    "cert-manager": (
        "release_name",
        "release_namespace",
        "release_status",
        "issuer_name",
    ),
    "argocd-bootstrap": (
        "release_name",
        "release_namespace",
        "release_status",
        "bootstrap_instructions",
    ),
}


def main() -> int:
    issues: list[str] = []
    for module_name, outputs in MODULE_OUTPUTS.items():
        outputs_tf = MODULES_DIR / module_name / "outputs.tf"
        if not outputs_tf.exists():
            issues.append(f"{outputs_tf} not found")
            continue
        content = outputs_tf.read_text()
        for output_name in outputs:
            if f'output "{output_name}"' not in content:
                issues.append(f"{outputs_tf} missing output {output_name}")
    if issues:
        sys.stderr.write("addons outputs checks failed:\n")
        sys.stderr.write("\n".join(f"- {issue}" for issue in issues) + "\n")
        return 1
    print("addons modules expose release and status outputs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
