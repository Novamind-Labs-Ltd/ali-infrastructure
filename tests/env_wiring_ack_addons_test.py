#!/usr/bin/env python3
"""Environment wiring checks for ACK cluster and addon modules."""

from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
ENVS_DIR = REPO_ROOT / "infra" / "envs"

MODULE_START = re.compile(r'module\s+"(?P<name>[^"]+)"\s*{', re.MULTILINE)


def extract_block(content: str, module_name: str) -> str | None:
    matches = list(MODULE_START.finditer(content))
    for idx, match in enumerate(matches):
        if match.group("name") != module_name:
            continue
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(content)
        return content[start:end]
    return None


def check_env(env: str) -> list[str]:
    issues: list[str] = []
    main_tf = ENVS_DIR / env / "main.tf"
    if not main_tf.exists():
        return [f"{main_tf} not found"]
    content = main_tf.read_text()
    ack_block = extract_block(content, "ack_cluster")
    if not ack_block:
        return [f"{main_tf} missing module ack_cluster"]
    required_ack_patterns = (
        r"vpc_id\s*=\s*module\.foundation_network\.vpc_id",
        r"vswitch_ids\s*=\s*module\.foundation_network\.private_subnet_ids",
        r"node_pool_vswitch_ids\s*=\s*module\.foundation_network\.private_subnet_ids",
        r"name_prefix\s*=\s*var\.ack_name_prefix",
    )
    for pattern in required_ack_patterns:
        if not re.search(pattern, ack_block):
            issues.append(f"{main_tf} ack_cluster missing '{pattern}'")

    addon_blocks = {
        "addons_ingress_nginx": "ingress-nginx.yaml",
        "addons_externaldns": "externaldns.yaml",
        "addons_cert_manager": "cert-manager.yaml",
        "addons_argocd_bootstrap": "argocd-bootstrap.yaml",
    }
    for module_name, values_file in addon_blocks.items():
        block = extract_block(content, module_name)
        if not block:
            issues.append(f"{main_tf} missing module {module_name}")
            continue
        if not re.search(r"kubeconfig_path\s*=\s*var\.ack_kubeconfig_path", block):
            issues.append(f"{main_tf} {module_name} missing kubeconfig_path wiring")
        values_pattern = rf'values_file\s*=\s*".*values/{values_file}"'
        if not re.search(values_pattern, block):
            issues.append(f"{main_tf} {module_name} missing values_file wiring")

    return issues


def main() -> int:
    issues: list[str] = []
    for env in ("dev", "prod"):
        issues.extend(check_env(env))

    if issues:
        sys.stderr.write("Environment wiring checks failed:\n")
        sys.stderr.write("\n".join(f"- {issue}" for issue in issues) + "\n")
        return 1

    print("Environment wiring includes ACK cluster inputs and addon values files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
