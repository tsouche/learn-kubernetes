#!/bin/bash

echo "======================================================================="
echo "|  Initial configuration of the VM (k8s_bootstrap_shared_base.sh)     |"
echo "======================================================================="
echo "..."


# Vagrant hack: from https://github.com/Yolean/kubeadm-vagrant

echo "======================================================================="
echo "Vagrant hack - declare  all nodes in /etc/hosts"
echo "======================================================================="
echo "..."

sed -i 's/127.*k8s/#\0/' /etc/hosts
printf "192.168.0.200  k8s-master k8s-master\n" >> /etc/hosts
printf "192.168.0.201  k8s-slave1 k8s-slave1\n" >> /etc/hosts
printf "192.168.0.202  k8s-slave2 k8s-slave2\n" >> /etc/hosts

echo "..."
echo "done"
echo "..."

# Disable Swap. You MUST disable swap in order for the kubelet to work properly

echo "======================================================================="
echo "Disable swap"
echo "======================================================================="
echo "..."

swapoff -a
sed -r 's/^(.*swap.*)$/# \1/g' -i /etc/fstab

echo "..."
echo "done"
echo "..."

# refresh the packages

echo "======================================================================="
echo "Refresh all packages lists"
echo "======================================================================="
echo "..."

apt-get update
#apt-get upgrade -y

echo "..."
echo "done"
echo "..."

# install docker and run it as a service

echo "======================================================================="
echo "Install docker"
echo "======================================================================="
echo "..."

apt-get install -y apt-transport-https ca-certificates curl gnupg-agent \
    software-properties-common
curl curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    bionic stable"
apt-get update
apt-get install -y docker-ce=5:18.09.9~3-0~ubuntu-bionic \
    docker-ce-cli=5:18.09.9~3-0~ubuntu-bionic containerd.io
systemctl enable docker && systemctl start docker

groupadd docker
usermod -aG docker vagrant

echo "..."
echo "done"
echo "..."

# create user 'thierry' (pwd='') with sudo privilege

echo "======================================================================="
echo "Create user 'thierry'"
echo "======================================================================="
echo "..."

adduser --disabled-password --gecos "" thierry
usermod -aG sudo thierry
usermod -aG docker thierry

echo "..."
echo "done"
echo "..."

# install kubernetes

echo "======================================================================="
echo "Install Kubernetes"
echo "======================================================================="
echo "..."

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update
apt-get install -y kubelet=1.16.4-00 kubeadm=1.16.4-00 kubectl=1.16.4-00
apt-mark hold kubelet kubeadm kubectl

# in perspective of using Flannel, secure that the bridged IPv4 traffic is 
# passed to iptable
sysctl net.bridge.bridge-nf-call-iptables=1

echo "..."
echo "done"
echo "..."

echo "======================================================================="
echo " The END (k8s_bootstrap_shared_base.sh)"
echo "======================================================================="

