#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <VPS_IP> [ssh_port]"
  echo "Example: $0 72.61.207.36"
  exit 1
fi

VPS_IP="$1"
SSH_PORT="${2:-22}"
ROOT_USER="${ROOT_USER:-root}"
PUBKEY_PATH="${BOOTSTRAP_PUBKEY_PATH:-$HOME/.ssh/hostinger_ed25519.pub}"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: ansible-playbook not found. Install Ansible first."
  exit 1
fi

if ! command -v sshpass >/dev/null 2>&1; then
  echo "Error: sshpass is required for first-run password SSH."
  echo "Install with: sudo apt install -y sshpass"
  exit 1
fi

if [[ ! -f "$PUBKEY_PATH" ]]; then
  echo "Error: public key not found at $PUBKEY_PATH"
  echo "Set BOOTSTRAP_PUBKEY_PATH=/path/to/key.pub and retry."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

echo "Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml >/dev/null

TMP_INVENTORY="$(mktemp --suffix=.yml)"
trap 'rm -f "$TMP_INVENTORY"' EXIT

cat > "$TMP_INVENTORY" <<EOF
all:
  children:
    vps:
      hosts:
        bootstrap-target:
          ansible_host: ${VPS_IP}
          ansible_user: ${ROOT_USER}
          ansible_port: ${SSH_PORT}
          ansible_ssh_common_args: "-o PreferredAuthentications=password -o PubkeyAuthentication=no"
EOF

if ! ansible -i "$TMP_INVENTORY" vps --list-hosts | grep -q "bootstrap-target"; then
  echo "Error: failed to build inventory target group 'vps'."
  exit 1
fi

echo "Bootstrapping $VPS_IP as $ROOT_USER on port $SSH_PORT"
echo "You will be prompted for the root SSH password once."

ansible-playbook playbooks/bootstrap.yml \
  -i "$TMP_INVENTORY" \
  --ask-pass \
  -e "bootstrap_user_ssh_public_key_path=${PUBKEY_PATH}"

echo ""
echo "Bootstrap complete."
echo "Next login should be key-based as: ssh pablo@${VPS_IP}"
