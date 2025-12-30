#!/usr/bin/env python3
"""Structural checks for module and environment scaffolding."""

from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
INFRA_DIR = REPO_ROOT / "infra"
MODULES_DIR = INFRA_DIR / "modules"
ENVS_DIR = INFRA_DIR / "envs"

MODULE_FILES = ("main.tf", "variables.tf", "outputs.tf", "README.md")
MODULE_PATHS = [
    MODULES_DIR / "foundation-network",
    MODULES_DIR / "ack-cluster",
    MODULES_DIR / "addons" / "ingress-nginx",
    MODULES_DIR / "addons" / "externaldns",
    MODULES_DIR / "addons" / "cert-manager",
    MODULES_DIR / "addons" / "argocd-bootstrap",
]

ENV_FILES = ("main.tf", "variables.tf", "dev.tfvars.example")
VALUES_README = ("values", "README.md")
ENV_MODULES = [
    "foundation_network",
    "ack_cluster",
    "addons_ingress_nginx",
    "addons_externaldns",
    "addons_cert_manager",
    "addons_argocd_bootstrap",
]


def check_paths() -> list[str]:
    missing: list[str] = []
    for module_path in MODULE_PATHS:
        for filename in MODULE_FILES:
            path = module_path / filename
            if not path.exists():
                missing.append(str(path.relative_to(REPO_ROOT)))
    for env in ("dev", "prod"):
        env_dir = ENVS_DIR / env
        for filename in ENV_FILES:
            path = env_dir / filename
            if not path.exists():
                missing.append(str(path.relative_to(REPO_ROOT)))
        values_path = env_dir / VALUES_README[0] / VALUES_README[1]
        if not values_path.exists():
            missing.append(str(values_path.relative_to(REPO_ROOT)))
    return missing


def check_env_wiring() -> list[str]:
    issues: list[str] = []
    module_block = re.compile(r'module\s+"(?P<name>[^"]+)"\s*{(?P<body>[\s\S]*?)}', re.MULTILINE)
    for env in ("dev", "prod"):
        main_tf = ENVS_DIR / env / "main.tf"
        if not main_tf.exists():
            continue
        content = main_tf.read_text()
        if "remote_state = {" not in content:
            issues.append(f"infra/envs/{env}/main.tf missing local.remote_state block")
        if "environment =" not in content:
            issues.append(f"infra/envs/{env}/main.tf missing local.environment")
        blocks = {match.group("name"): match.group("body") for match in module_block.finditer(content)}
        for module_name in ENV_MODULES:
            if module_name not in blocks:
                issues.append(f"infra/envs/{env}/main.tf missing module {module_name}")
                continue
            body = blocks[module_name]
            if "environment  = local.environment" not in body:
                issues.append(
                    f"infra/envs/{env}/main.tf module {module_name} missing environment wiring"
                )
            if "remote_state = local.remote_state" not in body:
                issues.append(
                    f"infra/envs/{env}/main.tf module {module_name} missing remote_state wiring"
                )
    return issues


def main() -> int:
    missing = check_paths()
    issues = check_env_wiring()
    if missing or issues:
        if missing:
            sys.stderr.write("Missing scaffolded paths:\n")
            sys.stderr.write("\n".join(f"- {path}" for path in missing) + "\n")
        if issues:
            sys.stderr.write("Environment wiring issues:\n")
            sys.stderr.write("\n".join(f"- {issue}" for issue in issues) + "\n")
        return 1
    print("Module and environment scaffolding structure is present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
