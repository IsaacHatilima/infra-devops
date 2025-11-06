# Proxmox Actions

Create A template on proxmox.

## Download Image

```bash
# Ubuntu 24.04 Minimal Cloud Image
wget https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img

# Debian 13 Bookworm Cloud Image
wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2
```

## Add Serial VGA Console

```bash
qm set 9999 --serial0 socket --vga serial0
```

### Convert the image to qcow2 format

```bash
mv ubuntu-24.04-minimal-cloudimg-amd64.img ubuntu-24.04-minimal-cloudimg-amd64.qcow2
```

### Resize the image

```bash
qemu-img resize ubuntu-24.04-minimal-cloudimg-amd64.qcow2 32G
```

### Set timezone

```bash
virt-customize -a ubuntu-24.04-minimal-cloudimg-amd64.qcow2 --timezone "Europe/Berlin"
```

### Install basic utilities and monitoring tools

```bash
virt-customize -a ubuntu-24.04-minimal-cloudimg-amd64.qcow2 --install curl,wget,git,htop,unzip,fail2ban,ufw,iputils-ping,nano,qemu-guest-agent,resolvconf
```

### Reset machine-id for cloning

```bash
virt-customize -a ubuntu-24.04-minimal-cloudimg-amd64.qcow2 --run-command "truncate -s 0 /etc/machine-id; ln -sf /etc/machine-id /var/lib/dbus/machine-id"
```

### Change SSH Port

```bash
virt-customize -a ubuntu-24.04-minimal-cloudimg-amd64.qcow2 \
  --run-command "sed -i 's/#Port 22/Port 1992/' /etc/ssh/sshd_config" \
  --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config" \
  --run-command "sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config" \
  --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/' /etc/ssh/sshd_config" \
  --run-command "sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config" \
  --run-command "systemctl enable ssh"
```

### Configure UFW firewall

#### Assuming the WireGuard VPN subnet is 10.100.100.0/24

```bash
virt-customize -a ubuntu-24.04-minimal-cloudimg-amd64.qcow2 \
--run-command "ufw default deny incoming" \
--run-command "ufw default allow outgoing" \
--run-command "ufw allow from 10.100.100.0/24 to any port 1992" \
--run-command "ufw allow from 5.9.237.105 to any port 1992" \
--run-command "ufw enable" \
--run-command "ufw reload"
```

## Import the image into Proxmox

```bash
qm importdisk 9999 ubuntu-24.04-minimal-cloudimg-amd64.qcow2 local
```

## Back on Proxmox Web UI

### Set the VM to use the imported disk

1. Go to the VM's hardware settings.
2. Select the hard disk you imported.
3. Enable Discard and set SSD emulation if Host is SSD.
4. Add

### Configure Boot Order

1. Go to the VM's Options tab.
2. Set the Boot Order and set disk to second and enable it.
