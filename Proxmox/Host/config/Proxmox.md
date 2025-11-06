# 🖥️ Install Proxmox VE on Debian 13 Trixie

```bash
https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie
```

## Comment enterprise repo

```bash
comment all lines in
nano /etc/apt/sources.list.d/pve-enterprise.sources
```

## Add Proxmox User

Add password to root user for Proxmox root access. None root users have no access to functionality like ACME

```bash
sudo -i
passwd
```

Create a new user for Proxmox with administrator privileges:

```bash
pveum useradd username@pam --password Passowrd
```

```bash
pveum aclmod / -user username@pam -role Administrator
```

## 📝 Server Configuration For Cloudflare Certificates

To configure the server for Cloudflare certificates, perform the following steps:

```bash

mkdir -p /root/.secrets
nano /root/.secrets/cloudflare.ini
# In /root/.secrets/cloudflare.ini add the following lines:
dns_cloudflare_api_token = <TOKEN_FROM_CLOUDFLARE>
chmod 600 /root/.secrets/cloudflare.ini
apt update && apt install -y certbot python3-certbot-dns-cloudflare

```

When server is back online, you can access the Proxmox web interface at `https://<server-ip>:8006`
using the username `root@pam` and the password you set earlier or the user you added to Proxmox.
If network bridge is not showing up in Proxmox, check `/etc/network/interfaces` to make sure the bridge
configuration was saved.
