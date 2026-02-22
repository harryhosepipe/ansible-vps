# VPS Bootstrap with Ansible

Minimal Ansible repo to bring up a fresh Ubuntu/Debian VPS with:
- package updates
- baseline tools
- UFW firewall
- fail2ban
- unattended security upgrades
- optional non-root deploy user

## 1. Install dependencies

```bash
ansible-galaxy collection install -r requirements.yml
```

## 2. Configure inventory

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

## 3. Configure variables

Edit `group_vars/all.yml`:
- `timezone`
- `ufw_allowed_tcp_ports`
- `create_deploy_user`
- `deploy_user_ssh_public_key` (if creating a deploy user)

## 4. Run bootstrap

```bash
ansible-playbook playbooks/bootstrap.yml
```

## 5. Suggested next roles

- Docker / container runtime
- App runtime (Node, Python, etc.)
- Reverse proxy (Nginx/Caddy)
- Backup + monitoring
