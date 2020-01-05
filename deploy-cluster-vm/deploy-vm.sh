#!/bin/bash

echo "======================================================================="
echo "|  Deploying a Kubernetes cluster of 3 VMs (deploy.sh)                |"
echo "======================================================================="
echo " "

# This script is executed as 'thierry' on the laptop, and launches the 
# deployment of the cluster, retrieves the token to log into the dashboard,
# and launches the dashboard in a broswer

# Requirements:
#  - virtualbox v6.0
#  - vagrant v2.2.6
#  - kubectl v1.16.4

# Configuration files:
#     ./deploy.sh (this file)
#     ./Vagrantfile
#     .source/k8s_bootstrap_shared_base.sh
#     .source/k8s_bootstrap_master.sh
#     .source/k8s_bootstrap_slave.sh
#     .source/weave-v1.10.yaml
#     .source/dashboard-v200b8-recommended.yaml
#     .source/dashboard-adminuser.yaml

# We give here the path relative to the Host (and the absolute path in a node)
dashboard_token_path="./temp/data_dashboard_token"


echo "======================================================================="
echo " Remove temporary files"
echo "======================================================================="
echo "..."

if [ -f "ubuntu-bionic-18.04-cloudimg-console.log" ]
then
    rm ubuntu-bionic-18.04-cloudimg-console.log
fi
if [ -d "./.kube" ]
then
    rm -rf ./.kube
fi
if [ -d "~/.kube" ]
then
    rm -rf ~/.kube
fi
if [ -d "./temp" ]
then
    rm -rf ./temp
fi
mkdir ./temp

echo "done"
echo "..."
echo " "

# Launches the 3 VMs, initialize the Kubernetes cluster and get the two slaves
# to join

echo "======================================================================="
echo " Launch the creation of the VMs with Vagrant"
echo "======================================================================="
echo "..."

vagrant up

echo "======================================================================="
echo "copy .kube/config in local home"
echo "======================================================================="
echo "..."

rm -fr ~/.kube
mkdir ~/.kube
cp ./.kube/config ~/.kube

echo "done"
echo "..."
echo " "

echo "======================================================================="
echo "List the cluster's nodes"
echo "======================================================================="
echo "..."

kubectl get nodes

echo "done"
echo "..."
echo " "

# Extract the token needed for the browser to log into the dashboard
echo "======================================================================="
echo "Get Dashboard Token"
echo "======================================================================="
echo "..."

admin_profile=$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
dashboard_token_full=$(kubectl -n kubernetes-dashboard describe secret $admin_profile | grep "token: ")
dashboard_token=${dashboard_token_full#"token: "}
touch "${dashboard_token_path}"
echo $dashboard_token > "${dashboard_token_path}"

echo "done"
echo "..."
echo " "

echo "======================================================================="
echo "Log into each node from a new tab"
echo "======================================================================="
echo "..."

gnome-terminal --tab -- vagrant ssh k8s-master
gnome-terminal --tab -- vagrant ssh k8s-slave1
gnome-terminal --tab -- vagrant ssh k8s-slave2

echo "done"
echo "..."
echo " "

echo "======================================================================="
echo "Start kube proxy in another tab of the existing terminal"
echo "======================================================================="
echo "..."

gnome-terminal --tab -- kubectl proxy -p 8001 &

echo "done"
echo "..."
echo " "

echo "======================================================================="
echo "Launch dashboard in a web browser"
echo "======================================================================="
echo "..."

xdg-open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ &

echo " "
echo "Here is the token needed to log into the dashboard:"
cat "${dashboard_token_path}"
echo " "

echo "done"
echo "..."
echo " "
echo "======================================================================="
echo " The END (deploy.sh)"
echo "======================================================================="


