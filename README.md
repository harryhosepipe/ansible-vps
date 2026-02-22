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

## Requirements

```bash
ansible-galaxy collection install -r requirements.yml
```

## Configure target host

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

## Run bootstrap

```bash
ansible-playbook playbooks/bootstrap.yml
```

## Notes

- Run from your local machine against remote VPS hosts over SSH.
- Default SSH key path is `~/.ssh/hostinger_ed25519.pub` on your local machine.
- Arch hosts are supported for package install/hardening, but unattended auto-updates are not configured by this playbook.
