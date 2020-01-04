#!/bin/bash

echo "======================================================================="
echo "|  Configuring the Master Node (k8s_boostrap_master.sh)               |"
echo "======================================================================="
echo "..."

master_ip_address="192.168.0.200"
token_path="/vagrant/temp/data_k8s_token"
ca_cert_hash_path="/vagrant/temp/data_k8s_ca_cert_hash"
dashboard_token_path="/vagrant/temp/data_dashboard_token"
config_files_path="/vagrant/source"

# Initialize the cluster
########################

echo "======================================================================="
echo "Initialize the K8s cluster"
echo "======================================================================="
echo "..."

# Generate token to be shared between master and nodes
kubeadm token generate > "${token_path}"

# Init Kubeadm 
kubeadm init --token $(cat "${token_path}") --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$master_ip_address

# Generate discovery token ca cert hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > "${ca_cert_hash_path}"

# Enable pods scheduling on Master
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "..."
echo "done"
echo "..."

echo "======================================================================="
echo "Copy the .kube/config"
echo "======================================================================="
echo "..."

# Enable using the cluster as root
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Enable using the cluster as 'vagrant' regular user
su vagrant -c 'mkdir -p $HOME/.kube'
su vagrant -c 'sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config'
su vagrant -c 'sudo chown $(id -u):$(id -g) $HOME/.kube/config'

# Save the precious 'config' file on the shared directory
if [ -d "/vagrant/.kube" ]
then
    rm -rf /vagrant/.kube
fi
mkdir -p /vagrant/.kube
sudo cp -i $HOME/.kube/config /vagrant/.kube/

echo "..."
echo "done"
echo "..."


echo "======================================================================="
echo "Deploy the network add-on"
echo "======================================================================="
echo "..."

# Flannel
# For flannel to work correctly, --pod-network-cidr=10.244.0.0/16 has to be passed to kubeadm init
# curl -o /vagrant/kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
# ... use the private interface, https://kubernetes.io/docs/setup/independent/troubleshooting-kubeadm/ - Default NIC When using flannel as the pod network in Vagrant
# sed 's#"/opt/bin/flanneld",#"/opt/bin/flanneld", "--iface=eth1",#' -i /vagrant/kube-flannel.yml

# Weave Net
kubectl apply -f $config_files_path/weave-v1.10.yaml

echo "..."
echo "done"
echo "..."

# Deploy the web UI - the Dashboard
###################################

echo "======================================================================="
echo "Install Kubernetes Dashboard"
echo "======================================================================="
echo "..."

# IT SEEMS IMPORTANT TO WAIT UNTIL THE CORE SERVICES ARE UP AND RUNNING.
# SOI WE INHIBIT THIS SECTION

# Wait 5 seconds to give time for the nodes to get active and running
echo "..... wait 5 seconds ....."

sleep 5

echo "..."
echo "done"
echo "..."

# retrieve the yaml file with the proper version 
#curl -Lo /vagrant/source/recommended.yaml https://raw.githubusercontent.com/kubernetes/dashboard/$dashboard_version/aio/deploy/recommended.yaml
# deploy the dashboard service
kubectl apply -f /vagrant/source/dashboard-v200b8-recommended.yaml
# create the sample user with the right to access the dashboard"
kubectl apply -f /vagrant/source/dashboard-adminuser.yaml

echo "..."
echo "done"
echo "..."

# Wait 5 seconds to give time for the dashboard to be deployed and the user to 
# be created
#echo "..... wait 5 seconds ....."

#sleep 5

#echo "..."
#echo "done"
#echo "..."

echo "======================================================================="
echo "The END (k8s_boostrap_master.sh)"
echo "======================================================================="
