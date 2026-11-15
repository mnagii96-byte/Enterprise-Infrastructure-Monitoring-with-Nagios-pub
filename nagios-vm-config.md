# Nagios VM Config

Steps to install Nagios Core 4.5.1 and Nagios Plugins 2.3.3 from source on an Ubuntu VM.

## Versions

| Component | Version |
|-----------|---------|
| Nagios Core | 4.5.1 |
| Nagios Plugins | 2.3.3 |
| Install prefix | `/usr/local/nagios` |
| Web server | Apache2 + PHP |

## 1. Update the system

```bash
sudo apt update && sudo apt full-upgrade
```

## 2. Install dependencies

```bash
sudo apt install -y autoconf build-essential wget unzip apache2 apache2-utils \
  libapache2-mod-php php libgd-dev snmp libnet-snmp-perl gettext libssl-dev \
  bc gawk dc libmcrypt-dev
```

## 3. Create the Nagios user and groups

```bash
sudo useradd nagios
sudo groupadd nagcmd
sudo usermod -aG nagcmd nagios
sudo usermod -aG nagcmd www-data
```

## 4. Download and extract Nagios Core

```bash
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.1.tar.gz
tar xzf nagios-4.5.1.tar.gz
cd nagios-4.5.1/
```

## 5. Configure and compile

```bash
sudo ./configure --with-nagios-group=nagios --with-command-group=nagcmd
sudo make all
```

## 6. Install

```bash
sudo make install
sudo make install-init
sudo make install-config
sudo make install-commandmode
sudo make install-webconf
```

## 7. Configure Apache

```bash
sudo a2enmod rewrite cgi
sudo systemctl restart apache2
```

## 8. Create the web admin user

```bash
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
```

## 9. Install Nagios Plugins

```bash
cd ~
wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz
tar xvf nagios-plugins-2.3.3.tar.gz
cd nagios-plugins-2.3.3/
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make
sudo make install
```

Plugins are installed to `/usr/local/nagios/libexec`.

## 10. Start Nagios

```bash
sudo systemctl start nagios
sudo systemctl enable nagios
```

## Verify

```bash
# Validate configuration
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Check service status
sudo systemctl status nagios

# Confirm plugins are present
ls /usr/local/nagios/libexec
```

Web UI: `http://<server-ip>/nagios` (log in as `nagiosadmin`).

## Notes

- If all hosts show DOWN, check that `/usr/local/nagios/libexec` is populated (for example `check_ping`). An empty directory means the plugin build in step 9 did not complete.
- Deploying plugins and NRPE to the monitored servers is covered by the Ansible playbook in this repo (`nagios-plugins.yml`).
