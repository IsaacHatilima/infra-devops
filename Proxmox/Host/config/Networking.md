# Network Config

## Edit `/etc/sysctl.conf` and add

```bash
net.ipv6.conf.all.forwarding=1
net.ipv4.ip_forward=1
```

sudo sysctl -p /etc/sysctl.conf

## 🌐 Enable NAT and IP Forwarding

Run the following commands to enable NAT and IP forwarding:

```bash
sudo iptables -P FORWARD ACCEPT
sudo iptables -A INPUT -i vmbr62 -p icmp -j ACCEPT
sudo iptables -A INPUT -i vmbr41 -p icmp -j ACCEPT
sudo netfilter-persistent save
```

Apply changes:

```bash
   ifreload -a
```

```bash
nano /etc/network/interfaces
```

Add the following lines to create a network bridge:

```bash

# Add to host network config section. We assume 172.20.20.207 is Host IP
post-up  iptables -t nat --append PREROUTING --protocol tcp --destination 172.20.20.207 --dport 443 -j REDIRECT --to-ports 8006
pre-down iptables -t nat --delete PREROUTING --protocol tcp --destination 172.20.20.207 --dport 443 -j REDIRECT --to-ports 8006

# If you have public IP subnet
auto vmbr0
iface vmbr0 inet static
  address 172.20.20.207
  bridge-ports none
  bridge-stp off
  bridge-fd 0

  # Public IPs from public subnet
  up ip route add <Subnet-IP>/32 dev vmbr0

  post-up echo 1 > /proc/sys/net/ipv4/ip_forward
  post-up echo 1 > /proc/sys/net/ipv4/conf/enp8s0/proxy_arp
  post-up echo 1 > /proc/sys/net/ipv4/conf/vmbr0/proxy_arp
#Examples of Subnets to add

auto vmbr1
iface vmbr1 inet static
  address 192.168.10.1/24
  bridge-ports none
  bridge-stp off
  bridge-fd 0

auto vmbr2
iface vmbr2 inet static
  address 172.200.200.1/24
  bridge-ports none
  bridge-stp off
  bridge-fd 0
```

## Add MASQUERADE IP Rules

```bash
sudo iptables -t nat -A POSTROUTING -s <Public-Subnet>/29 -o enp35s0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o enp35s0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 172.200.200.0/24 -o enp35s0 -j MASQUERADE
```

## NATed Public IP config on Ubuntu Server

```bash

# Ubuntu network config for public NATed subnet
# sudo nano /etc/netplan/01-netcfg.yaml
network:
    version: 2
    ethernets:
        eth0:
            addresses:
            - <Server-IP>/24
            match:
                macaddress: ac:b4:c1:d2:ea:fa
            nameservers:
                addresses:
                - 1.1.1.1
                - 8.8.8.8
                search: []
            routes:
            -   to: default
                via: 172.20.20.207
            set-name: eth0
```
