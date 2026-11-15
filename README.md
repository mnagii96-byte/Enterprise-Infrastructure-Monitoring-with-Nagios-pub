# Nagios Monitoring with Ansible

Ansible automation for deploying Nagios plugins and NRPE across all servers, plus notes on the Nagios Core server that monitors them.

## Overview

| Item | Value |
|------|-------|
| Nagios server hostname | `nagios` |
| Nagios server IP | `10.13.1.85` |
| OS | Ubuntu (questing) |
| Install method | Built from source under `/usr/local/nagios` |
| Plugin directory (server) | `/usr/local/nagios/libexec` |
| Plugin directory (agents) | `/usr/lib/nagios/plugins` |
| Automation | Ansible, run from a master node against `inventory.ini` |

### Monitored hosts

- `app01`
- `db01`
- `web01`
- `mc01`
- `rmq01`
- `localhost` (the Nagios server itself)

## Repository layout

```
.
├── README.md
├── inventory.ini          # Ansible inventory (all monitored hosts + nagios group)
└── nagios-plugins.yml     # Playbook: plugins + NRPE on all hosts
```

## Prerequisites

- Ansible installed on the master node
- SSH access (key-based) from the master node to every host, with sudo privileges
- The Nagios server reachable from all hosts on TCP `5666` (NRPE)
- The `community.general` collection (used for the optional ufw rule):

```bash
ansible-galaxy collection install community.general
```

## Inventory example

```ini
[nagios]
nagios

[monitored]
app01
db01
web01
mc01
rmq01

[all:vars]
ansible_user=ansible
```

## What the playbook does

**On all hosts (`hosts: all`):**

1. Updates the apt cache.
2. Installs `monitoring-plugins-basic`, `monitoring-plugins-standard` and `nagios-nrpe-server`.
3. Sets `allowed_hosts` in `/etc/nagios/nrpe.cfg` to include the Nagios server (`10.13.1.85`).
4. Defines basic NRPE commands in `/etc/nagios/nrpe_local.cfg`: `check_users`, `check_load`, `check_disk`, `check_procs`.
5. Enables and starts `nagios-nrpe-server`.
6. Opens port `5666/tcp` to the Nagios server if ufw is active.





## Usage

```bash
# Dry run
ansible-playbook -i inventory.ini nagios-plugins.yml --check

# Deploy
ansible-playbook -i inventory.ini nagios-plugins.yml

# Limit to one host
ansible-playbook -i inventory.ini nagios-plugins.yml --limit web01
```

## Verifying

On the Nagios server:

```bash
# Plugins present?
ls /usr/local/nagios/libexec

# Test ICMP check against a host
/usr/local/nagios/libexec/check_ping -H app01 -w 100,20% -c 200,60%

# Test NRPE connectivity
/usr/local/nagios/libexec/check_nrpe -H app01
```

Validate the Nagios configuration before restarting:

```bash
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
sudo systemctl restart nagios
```
