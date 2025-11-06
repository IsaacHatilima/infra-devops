# Config VPN Server

## Update System Packages

```bash
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
```

## Set Timezone

```bash
sudo timedatectl set-timezone Europe/Berlin
```

## Install Basic Packages

```bash
sudo apt install curl wget git htop unzip fail2ban -y
```

## Add Terminus Key

```bash
    mkdir -p ~/.ssh
    nano ~/.ssh/authorized_keys
    chmod 700 ~/.ssh # Grants full access to user, denies all to others  
    chmod 600 ~/.ssh/authorized_keys # User can read/write, others have no access 
```

## 🔒 Harden SSH Access

Edit the SSH configuration file:

```bash
sudo nano /etc/ssh/sshd_config
```

Set the following:

```bash
Port <NEW-SSH-PORT>
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
UsePAM yes
X11Forwarding no

sudo apt install ufw -y
sudo ufw allow from 10.100.100.0/24 to any port <NEW-SSH-PORT> proto tcp
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw status verbose # Confirm the new SSH port is allowed
sudo ufw reload
```

Restart the SSH service:

```bash
sudo systemctl restart sshd
```
