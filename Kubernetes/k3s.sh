#!/bin/bash

#############################################
# USER SETTINGS
#############################################

KVVERSION="v1.0.1"
k3sVersion="v1.33.5+k3s1"

master1=192.168.10.9
master2=192.168.10.10
master3=192.168.10.11
master4=192.168.10.12

worker1=192.168.10.13
worker2=192.168.10.14
worker3=192.168.10.15
worker4=192.168.10.16
worker5=192.168.10.17
worker6=192.168.10.18
worker7=192.168.10.19
worker8=192.168.10.20
worker9=192.168.10.21
worker10=192.168.10.22

user=johndoe
ssh_port=123 # SSH Port if not default 22
interface=eth0
vip=192.168.10.254
lbrange=192.168.10.200-192.168.10.250
certName=id_ed25519

masters=($master2 $master3 $master4)
workers=($worker1 $worker2 $worker3 $worker4 $worker5 $worker6 $worker7 $worker8 $worker9 $worker10)
all=($master1 $master2 $master3 $master4 $worker1 $worker2 $worker3 $worker4 $worker5 $worker6 $worker7 $worker8 $worker9 $worker10)

#############################################
# MAIN EXECUTION
#############################################

sudo timedatectl set-ntp off && sudo timedatectl set-ntp on

# Install k3sup
if ! command -v k3sup &>/dev/null; then
  echo -e " \033[31;5mInstalling k3sup...\033[0m"
  curl -sLS https://get.k3sup.dev | sh
  sudo install k3sup /usr/local/bin/
else
  echo -e " \033[32;5mk3sup already installed\033[0m"
fi

# Install kubectl
if ! command -v kubectl &>/dev/null; then
  echo -e " \033[31;5mInstalling kubectl...\033[0m"
  curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
  echo -e " \033[32;5mkubectl already installed\033[0m"
fi

# Install policycoreutils on all nodes
for node in "${all[@]}"; do
  ssh -p $ssh_port -i ~/.ssh/$certName $user@$node "sudo NEEDRESTART_MODE=a apt-get install -y policycoreutils"
  echo -e " \033[32;5mPolicyCoreUtils installed on $node\033[0m"
done

# add open-iscsi - needed for Debian and non-cloud Ubuntu
echo -e " \033[36;5mInstalling open-iscsi on Longhorn nodes...\033[0m"
for node in "${workers[@]}"; do
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

# Bootstrap first master
mkdir -p ~/.kube
k3sup install \
  --ip $master1 \
  --user $user \
  --ssh-port $ssh_port \
  --tls-san $vip \
  --cluster \
  --sudo \
  --merge \
  --context k3s-ha \
  --ssh-key ~/.ssh/$certName \
  --local-path ~/.kube/config \
  --k3s-version $k3sVersion \
  --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$master1 --node-taint node-role.kubernetes.io/master=true:NoSchedule"

echo -e " \033[32;5mFirst master bootstrapped successfully!\033[0m"

# Install Kube-VIP
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/kube-vip
sed "s/\$interface/$interface/g; s/\$vip/$vip/g" kube-vip > ~/kube-vip.yaml
scp -i ~/.ssh/$certName -P $ssh_port ~/kube-vip.yaml $user@$master1:~/kube-vip.yaml
ssh -p $ssh_port -i ~/.ssh/$certName $user@$master1 "sudo mkdir -p /var/lib/rancher/k3s/server/manifests && sudo mv ~/kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml"

# Join other masters
for node in "${masters[@]}"; do
  k3sup join \
    --ip $node \
    --user $user \
    --ssh-port $ssh_port \
    --server \
    --server-ip $master1 \
    --sudo \
    --ssh-key ~/.ssh/$certName \
    --k3s-version $k3sVersion \
    --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$node --node-taint node-role.kubernetes.io/master=true:NoSchedule"
  echo -e " \033[32;5mMaster node $node joined successfully!\033[0m"
done

# Join workers
for node in "${workers[@]}"; do
  k3sup join \
    --ip $node \
    --user $user \
    --ssh-port $ssh_port \
    --sudo \
    --ssh-key ~/.ssh/$certName \
    --k3s-version $k3sVersion \
    --server-ip $master1 \
    --k3s-extra-args "--node-label longhorn=true --node-label worker=true"
  echo -e " \033[32;5mWorker node $node joined successfully!\033[0m"
done

# Kube-VIP Cloud Provider
kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

# MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/ipAddressPool
sed "s/\$lbrange/$lbrange/g" ipAddressPool > ~/ipAddressPool.yaml
kubectl apply -f ~/ipAddressPool.yaml

# Test LoadBalancer
kubectl apply -f https://raw.githubusercontent.com/inlets/inlets-operator/master/contrib/nginx-sample-deployment.yaml -n default
kubectl expose deployment nginx-1 --port=80 --type=LoadBalancer -n default

#echo -e " \033[32;5mWaiting for nginx pod to become ready...\033[0m"
#while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do sleep 2; done
echo -e " \033[32;5mWaiting for K3S to sync and LoadBalancer to come online\033[0m"
kubectl wait --for=condition=ready pod -l app=nginx -n default --timeout=180s

kubectl wait --namespace metallb-system --for=condition=ready pod --selector=component=controller --timeout=120s
kubectl apply -f ~/ipAddressPool.yaml
kubectl apply -f ./longhorn.yaml

kubectl get nodes -o wide
kubectl get svc -A
kubectl get pods -A -o wide

echo -e " \033[32;5m✅ Cluster Ready! Access via VIP: $vip:6443\033[0m"
echo -e " \033[32;5mHappy Kubing!\033[0m"
