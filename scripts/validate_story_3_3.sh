#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$repo_root"

run_py_tests() {
  python3 tests/ack_cluster_test.py
  python3 tests/addons_modules_test.py
  python3 tests/env_wiring_ack_addons_test.py
  python3 tests/addons_outputs_test.py
  python3 tests/ack_cluster_readme_test.py
  python3 tests/addons_readme_test.py
  python3 tests/foundation_network_test.py
  python3 tests/foundation_network_readme_test.py
  python3 tests/foundation_network_naming_test.py
  python3 tests/scaffold_structure_test.py
  python3 tests/remote_state_test.py
}

run_fmt_check() {
  terraform fmt -check \
    infra/modules/ack-cluster \
    infra/modules/addons/ingress-nginx \
    infra/modules/addons/externaldns \
    infra/modules/addons/cert-manager \
    infra/modules/addons/argocd-bootstrap \
    infra/envs/dev \
    infra/envs/prod
}

run_module_validations() {
  local dir
  for dir in \
    infra/modules/ack-cluster \
    infra/modules/addons/ingress-nginx \
    infra/modules/addons/externaldns \
    infra/modules/addons/cert-manager \
    infra/modules/addons/argocd-bootstrap
  do
    (cd "$repo_root/$dir" && terraform init -backend=false && terraform validate)
  done
}

run_env_validations_backend_false() {
  local dir
  for dir in infra/envs/dev infra/envs/prod
  do
    (cd "$repo_root/$dir" && terraform init -backend=false && terraform validate)
  done
}

run_env_validations_backend() {
  local dir
  for dir in infra/envs/dev infra/envs/prod
  do
    if [[ -f "$repo_root/$dir/backend.hcl" ]]; then
      (cd "$repo_root/$dir" && terraform init -backend-config=backend.hcl && terraform validate)
    else
      echo "backend.hcl missing in $dir; falling back to -backend=false" >&2
      (cd "$repo_root/$dir" && terraform init -backend=false && terraform validate)
    fi
  done
}

usage() {
  cat <<'USAGE'
Usage: scripts/validate_story_3_3.sh [mode]

Modes:
  all            Run Python tests, fmt check, module validate, env validate (backend=false)
  all-backend    Run Python tests, fmt check, module validate, env validate (backend.hcl)
  tests          Run Python tests only
  fmt            Run terraform fmt -check only
  modules        Run module terraform init/validate only
  env            Run env terraform init/validate with backend=false
  env-backend    Run env terraform init/validate with backend.hcl

Default: all
USAGE
}

mode="${1:-all}"

case "$mode" in
  all)
    run_py_tests
    run_fmt_check
    run_module_validations
    run_env_validations_backend_false
    ;;
  all-backend)
    run_py_tests
    run_fmt_check
    run_module_validations
    run_env_validations_backend
    ;;
  tests)
    run_py_tests
    ;;
  fmt)
    run_fmt_check
    ;;
  modules)
    run_module_validations
    ;;
  env)
    run_env_validations_backend_false
    ;;
  env-backend)
    run_env_validations_backend
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
