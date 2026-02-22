#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root on the VPS."
  exit 1
fi

REPO_URL="${REPO_URL:-https://github.com/harryhosepipe/ansible-vps.git}"
BRANCH="${BRANCH:-main}"
WORKDIR="${WORKDIR:-/opt/ansible-vps}"
BOOTSTRAP_USER="${BOOTSTRAP_USER:-pablo}"

if [[ -z "${BOOTSTRAP_PUBKEY:-}" ]]; then
  if [[ -r /dev/tty ]]; then
    echo "Paste the SSH public key for ${BOOTSTRAP_USER} (single line), then press Enter:" > /dev/tty
    read -r BOOTSTRAP_PUBKEY < /dev/tty
  elif [[ -t 0 ]]; then
    echo "Paste the SSH public key for ${BOOTSTRAP_USER} (single line), then press Enter:"
    read -r BOOTSTRAP_PUBKEY
  else
    echo "Error: BOOTSTRAP_PUBKEY is required in non-interactive mode."
    echo "Example: BOOTSTRAP_PUBKEY='ssh-ed25519 AAAA... you@host' bash bootstrap-on-vps.sh"
    exit 1
  fi
fi

if [[ -z "${BOOTSTRAP_PUBKEY}" ]]; then
  echo "Error: empty BOOTSTRAP_PUBKEY."
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  source /etc/os-release
else
  echo "Error: /etc/os-release not found. Unsupported distro."
  exit 1
fi

install_base_tools() {
  case "${ID:-}" in
    ubuntu|debian)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y curl ca-certificates git ansible
      ;;
    arch)
      pacman -Sy --noconfirm --needed curl ca-certificates git ansible
      ;;
    *)
      if [[ "${ID_LIKE:-}" == *"debian"* ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y curl ca-certificates git ansible
      elif [[ "${ID_LIKE:-}" == *"arch"* ]]; then
        pacman -Sy --noconfirm --needed curl ca-certificates git ansible
      else
        echo "Error: unsupported distro ID=${ID:-unknown} ID_LIKE=${ID_LIKE:-unknown}"
        exit 1
      fi
      ;;
  esac
}

install_base_tools

if [[ ! -d "${WORKDIR}/.git" ]]; then
  rm -rf "${WORKDIR}"
  git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${WORKDIR}"
else
  git -C "${WORKDIR}" fetch origin "${BRANCH}"
  git -C "${WORKDIR}" checkout -q "${BRANCH}" || git -C "${WORKDIR}" checkout -q -b "${BRANCH}" "origin/${BRANCH}"
  git -C "${WORKDIR}" pull --ff-only origin "${BRANCH}"
fi

ansible-galaxy collection install -r "${WORKDIR}/requirements.yml"

EXTRA_VARS_FILE="$(mktemp --suffix=.yml)"
trap 'rm -f "${EXTRA_VARS_FILE}"' EXIT

cat > "${EXTRA_VARS_FILE}" <<EOF_VARS
bootstrap_user: "${BOOTSTRAP_USER}"
bootstrap_user_ssh_public_key: |
  ${BOOTSTRAP_PUBKEY}
EOF_VARS

ansible-pull \
  -U "${REPO_URL}" \
  -C "${BRANCH}" \
  -d "${WORKDIR}" \
  -i "localhost," \
  playbooks/bootstrap-local.yml \
  -e "@${EXTRA_VARS_FILE}"

echo "Bootstrap complete."
echo "Now test login: ssh ${BOOTSTRAP_USER}@$(hostname -I | awk '{print $1}')"
