# ansible-vps

Single-playbook VPS bootstrap for Ubuntu, Debian, and Arch Linux.

What it does by default:
- updates system packages
- creates user `pablo` with home directory
- installs your SSH public key for `pablo`
- grants `pablo` passwordless sudo
- disables SSH password authentication (key-only)
- keeps root SSH login enabled (for now)
- enables firewall allowing `22`, `80`, `443`
- enables fail2ban
- enables unattended security updates on Debian/Ubuntu
- installs base apps: curl, git, neovim, htop, tmux, ripgrep, nodejs, npm, rsync, unzip
- enables corepack and activates latest pnpm

## Preferred flow: copy key from WSL, then run on VPS

1. From WSL, copy your key to root on the VPS:

```bash
ssh-copy-id -i ~/.ssh/hostinger_ed25519.pub root@72.61.207.36
```

2. SSH in:

```bash
ssh root@72.61.207.36
```

3. On the VPS, run:

```bash
curl -fsSL -o /tmp/bootstrap-on-vps.sh https://raw.githubusercontent.com/harryhosepipe/ansible-vps/main/scripts/bootstrap-on-vps.sh
bash /tmp/bootstrap-on-vps.sh
```

The script will automatically reuse the first key from `/root/.ssh/authorized_keys` (set by `ssh-copy-id`) and install it for `pablo`.

Fallback if no root key exists yet:

```bash
BOOTSTRAP_PUBKEY='ssh-ed25519 AAAA... you@machine' bash /tmp/bootstrap-on-vps.sh
```

What this does:
- installs `git` + `ansible` on the VPS
- pulls this repo with `ansible-pull`
- runs local bootstrap against `localhost`
- creates `pablo`, installs your key, applies hardening and packages

## Local machine flow (alternative)

Use this when you want to run from your laptop/WSL over SSH password:

```bash
sudo apt install -y sshpass
ansible-galaxy collection install -r requirements.yml
./scripts/bootstrap-fresh.sh 72.61.207.36
```

Optional:
- custom SSH port: `./scripts/bootstrap-fresh.sh 72.61.207.36 2222`
- custom local pubkey path:
  `BOOTSTRAP_PUBKEY_PATH=~/.ssh/other.pub ./scripts/bootstrap-fresh.sh 72.61.207.36`

## Inventory mode (advanced)

Edit `inventory/hosts.yml`:

```yaml
all:
  children:
    vps:
      hosts:
        my-vps:
          ansible_host: YOUR_SERVER_IP
          ansible_user: root
```

## Optional variable overrides

Edit `group_vars/all.yml` if needed:
- `bootstrap_user`
- `bootstrap_user_ssh_public_key_path`
- `ssh_disable_password_auth`
- `ssh_permit_root_login`
- `ufw_allowed_tcp_ports`
- `common_packages`

## Run bootstrap (inventory mode)

```bash
ansible-playbook playbooks/bootstrap.yml
```

## Notes

- `bootstrap-on-vps.sh` defaults:
  - `REPO_URL=https://github.com/harryhosepipe/ansible-vps.git`
  - `BRANCH=main`
  - `BOOTSTRAP_USER=pablo`
- You can override those as environment variables.
- Arch hosts are supported for package install/hardening, but unattended auto-updates are not configured by this playbook.
