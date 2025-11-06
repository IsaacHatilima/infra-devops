# 🏗️ Server Setup Guide

## 🔧 Boot Into Rescue Mode

Boot into **Hetzner Rescue Mode** and run:

```bash
   installimage
```

This will guide you through the installation process. Change Hostname to preferred hostname, click 2 to save then 10 to
quit, then continue with the next steps. Once installation is done, reboot and ssh into the server.

## 🔄 System Updates and Timezone Configuration

Run the following commands to update the system and set the timezone:

### Update System Packages

```bash
apt update && apt upgrade -y && apt autoremove -y
```

### Set Timezone and Locale

```bash
timedatectl set-timezone Europe/Berlin
```

### Install Basic Packages

```bash
apt install curl wget git htop unzip fail2ban libguestfs-tools -y
```

## 👤 Create Server User

Set a password for the host root (for Proxmox login) to be able to perform ACME actions. Create a new user with the
following commands:

```bash
adduser <username>
usermod -aG sudo <username>
```

## 🔑 Configure SSH Access

Edit the SSH configuration file:

```bash
su - <username-above>
mkdir -p ~/.ssh  
chmod 700 ~/.ssh # Grants full access to user, denies all to others  
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys # User can read/write, others have no access 
```

## 🔒 Harden SSH Access

Edit the SSH configuration file:

```bash
nano /etc/ssh/sshd_config
```

Set the following:

```bash
Port <NEW-SSH-PORT> # Recommended as extra security feature
PermitRootLogin prohibit-password
PasswordAuthentication no
PermitEmptyPasswords no
UsePAM yes
X11Forwarding no
```

Restart the SSH service:

```bash
systemctl restart sshd
```

## 🔥 Firewall Setup

```bash
sudo apt install iptables-persistent -y
# Ipv4
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8006 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A FORWARD -p icmp -j ACCEPT
# Ipv6
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -p tcp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p tcp --dport 8006 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -P INPUT DROP
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -A INPUT -p icmpv6 -j ACCEPT
ip6tables -A FORWARD -p icmpv6 -j ACCEPT

sudo netfilter-persistent save
# Verify rules
sudo iptables -L -v -n
sudo ip6tables -L -v -n
```

## 🔁 Reboot the Server

```bash
   reboot
```
