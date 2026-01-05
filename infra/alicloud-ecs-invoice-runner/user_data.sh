#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates curl git python3 python3-venv python3-pip unzip

# Optional: basic directories for agent work
mkdir -p /opt/invoice-agent
chown ubuntu:ubuntu /opt/invoice-agent || true

cat >/etc/motd <<'EOM'
Invoice Processor Runner
------------------------
This ECS instance was provisioned for running the invoice processing agent.

Next steps (example):
  1) scp your repo or git clone it to /opt/invoice-agent
  2) create a venv:   python3 -m venv /opt/invoice-agent/.venv
  3) activate:        source /opt/invoice-agent/.venv/bin/activate
  4) install deps:    pip install -r requirements.txt
  5) run your script per docs/tech-spec-invoice-processing.md

Remember: this instance is set to auto-release based on your budget.
EOM

