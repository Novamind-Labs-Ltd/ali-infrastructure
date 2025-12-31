#!/usr/bin/env python3
"""Structural checks for the addons Helm modules."""

from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
MODULES_DIR = REPO_ROOT / "infra" / "modules" / "addons"

MODULE_EXPECTATIONS = {
    "ingress-nginx": "ingress_nginx",
    "externaldns": "externaldns",
    "cert-manager": "cert_manager",
    "argocd-bootstrap": "argocd_bootstrap",
}

REQUIRED_VARIABLES = (
    "kubeconfig_path",
    "values_file",
)

PROVIDER_PATTERN = re.compile(
    r'required_providers\s*{\s*helm\s*=\s*{\s*source\s*=\s*"hashicorp/helm"\s*version\s*=\s*">=\s*2\.[0-9]+"\s*}',
    re.MULTILINE,
)
HELM_PROVIDER_BLOCK = re.compile(
    r'provider\s+"helm"\s*{[\s\S]*?kubernetes\s*=\s*{[\s\S]*?config_path\s*=\s*var\.kubeconfig_path',
    re.MULTILINE,
)


def check_module(module_dir: Path, release_name: str) -> list[str]:
    issues: list[str] = []
    main_tf = module_dir / "main.tf"
    variables_tf = module_dir / "variables.tf"
    if not main_tf.exists():
        return [f"{main_tf} not found"]
    if not variables_tf.exists():
        return [f"{variables_tf} not found"]
    main_content = main_tf.read_text()
    variables_content = variables_tf.read_text()

    if not PROVIDER_PATTERN.search(main_content):
        issues.append(f"{main_tf} missing required_providers helm")
    if not HELM_PROVIDER_BLOCK.search(main_content):
        issues.append(f"{main_tf} missing helm provider config_path wiring")
    release_pattern = re.compile(rf'resource\s+"helm_release"\s+"{release_name}"', re.MULTILINE)
    if not release_pattern.search(main_content):
        issues.append(f"{main_tf} missing helm_release {release_name}")

    for variable_name in REQUIRED_VARIABLES:
        if f'variable "{variable_name}"' not in variables_content:
            issues.append(f"{variables_tf} missing variable {variable_name}")

    return issues


def main() -> int:
    issues: list[str] = []
    for module_name, release_name in MODULE_EXPECTATIONS.items():
        module_dir = MODULES_DIR / module_name
        issues.extend(check_module(module_dir, release_name))

    if issues:
        sys.stderr.write("addons module checks failed:\n")
        sys.stderr.write("\n".join(f"- {issue}" for issue in issues) + "\n")
        return 1

    print("addons modules define helm providers, releases, and required variables")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
