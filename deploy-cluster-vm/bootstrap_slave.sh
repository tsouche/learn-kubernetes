#!/bin/bash

echo "======================================================================="
echo "|  Configuring the Slave Node (k8s_boostrap_slave.sh)                 |"
echo "======================================================================="
echo "..."

master_ip_address="192.168.0.200"
token_path="/vagrant/temp/data_k8s_token"
ca_cert_hash_path="/vagrant/temp/data_k8s_ca_cert_hash"

# Join Kubernetes Cluster

echo "======================================================================="
echo "Join the K8s cluster"
echo "======================================================================="
echo "..."

kubeadm join --token $(cat "${token_path}") $master_ip_address:6443 \
    --discovery-token-ca-cert-hash sha256:$(cat "${ca_cert_hash_path}")

echo "..."
echo "done"
echo "..."

echo "======================================================================="
echo "Copy the .kube/config"
echo "======================================================================="
echo "..."

# Enable using the cluster as 'vagrant' regular user
su vagrant -c 'mkdir -p $HOME/.kube'
su vagrant -c 'sudo cp -i /vagrant/.kube/config $HOME/.kube/'
su vagrant -c 'sudo chown $(id -u):$(id -g) $HOME/.kube/config'

echo "..."
echo "done"
echo "..."

# Cleanup
# rm -rf "${token_path}"
# rm -rf "${ca_cert_hash_path}"

echo "======================================================================="
echo "The END (k8s_boostrap_slave.sh)"
echo "======================================================================="
