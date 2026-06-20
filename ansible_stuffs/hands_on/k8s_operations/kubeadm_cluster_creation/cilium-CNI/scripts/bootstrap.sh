#!/usr/bin/env bash
# =============================================================================
#  bootstrap.sh  —  one-shot local prep + deploy
# -----------------------------------------------------------------------------
#  Installs Galaxy collections and runs the full deployment with the neon
#  k8s_beautified console output. Safe to re-run (idempotent playbooks).
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"

# ---- load environment -------------------------------------------------------
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
else
  echo "ERROR: .env not found. Copy .env.example to .env and edit it first." >&2
  exit 1
fi

# ---- required tooling -------------------------------------------------------
command -v ansible-playbook >/dev/null 2>&1 || {
  echo "ERROR: ansible-playbook not found. Install Ansible first." >&2
  exit 1
}

# ---- dependencies -----------------------------------------------------------
echo ">> Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml -p collections >/dev/null

# ---- connectivity check -----------------------------------------------------
echo ">> Checking SSH connectivity to all nodes..."
ansible all -m ping

# ---- deploy -----------------------------------------------------------------
echo ">> Deploying kubeadm + Cilium cluster..."
exec ansible-playbook playbooks/site.yml "$@"
