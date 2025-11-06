#!/bin/bash

#############################################
# YOU SHOULD ONLY NEED TO EDIT THIS SECTION #
#############################################
# Set the IP addresses of master1
master1=192.168.10.9

# Set the IP addresses of your Longhorn nodes
longhorn1=192.168.10.23
longhorn2=192.168.10.24
longhorn3=192.168.10.25
longhorn4=192.168.10.26

# User of remote machines
user=johndoe
ssh_port=1234 # SSH Port if not default 22
# Interface used on remotes
interface=eth0

# Set the virtual IP address (VIP)
vip=192.168.10.254

# Array of longhorn nodes
storage=($longhorn1 $longhorn2 $longhorn3 $longhorn4)

#ssh certificate name variable
certName=id_ed25519

#############################################
#            DO NOT EDIT BELOW              #
#############################################
# For testing purposes - in case time is wrong due to VM snapshots
sudo timedatectl set-ntp off
sudo timedatectl set-ntp on

# add open-iscsi - needed for Debian and non-cloud Ubuntu
echo -e " \033[36;5mInstalling open-iscsi on Longhorn nodes...\033[0m"
for node in "${storage[@]}"; do
  echo -e " \033[33;5m→ $node\033[0m"
  ssh -p $ssh_port -i ~/.ssh/$certName $user@$node " \
    if ! dpkg -l | grep -qw open-iscsi; then
        echo 'Installing open-iscsi...';
        sudo apt update -y && sudo apt install -y open-iscsi;
        sudo systemctl enable --now iscsid || sudo systemctl enable --now open-iscsi;
        sudo ln -sf /usr/sbin/iscsiadm /usr/bin/iscsiadm || true;
    else
        echo 'Open-iscsi already installed';
    fi"
done

# Step 1: Add new longhorn nodes to cluster (note: label added)
for newnode in "${storage[@]}"; do
  k3sup join \
    --ip $newnode \
    --user $user \
    --ssh-port $ssh_port \
    --sudo \
    --k3s-channel stable \
    --server-ip $master1 \
    --k3s-extra-args "--node-label \"longhorn=true\"" \
    --ssh-key $HOME/.ssh/$certName
  echo -e " \033[32;5mAgent node joined successfully!\033[0m"
done

# Step 2: Install Longhorn (using modified Official to pin to Longhorn Nodes)
echo -e "\n\033[34;1mInstalling Longhorn v1.10.0 on nodes with longhorn=true...\033[0m"

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.10.0/deploy/longhorn.yaml

# Step 3: Print out confirmation

echo -e " \033[32;5mHappy Kubing! Access Longhorn through Rancher UI\033[0m"