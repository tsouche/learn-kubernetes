#!/bin/bash

echo " "
echo "========================================================================"
echo "   Install a Kubernetes-cluster-in-Docker on a VM"
echo "========================================================================"
echo " "


# indicate the dashboard version to collect on the kind official site
VERSION=v2.0.0-beta8


# BEWARE - version compatibility matters.
# Since kind is running on Kubernetes v1.16, I had to:
#   - install a compatible version of kubectl (1.16.4)
#   - copy the dashboard YAML file v2.0.0-beta8 which is compatible with 
#       Kubernetes v1.16
#       https://github.com/kubernetes/dashboard/releases/tag/v2.0.0-beta8

cluster_configuration="/vagrant/kind-cluster.yaml"
cluster_name="newyear"
dashboard_configuration="/vagrant/recommended.yaml"
dasbboard_user="/vagrant/dashboard-adminuser.yaml"
dashboard_token_path="/vagrant/data_dashboard_token"




# Reminder: this script is executed as root, at the boot of the VM
# We assume here that the local /vagrant directory is shared with the host directory from where the Vagrantfile is run.
# update the package list
apt-get update


echo " "
echo "========================================================================"
echo " Install docker"
echo "========================================================================"
echo " "

# Install docker (as root)
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
# create the user/group to be able to use it as 'vagrant' regular user
groupadd docker
usermod -aG docker vagrant

echo " done"
echo " "
echo "========================================================================"
echo " Install GO v1.13"
echo "========================================================================"
echo " "

sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install -y golang-1.13
export PATH=$PATH:/usr/lib/go-1.13/bin

echo " done"
echo " "
echo "========================================================================"
echo " Install kind v0.6.1"
echo "========================================================================"
echo " "

# The binary file is available in the shared directory: copy it in t a bin directory
cp /vagrant/kind-v0.6.1-Linux-amd64 /usr/lib/go-1.13/bin/kind
chmod +x /usr/lib/go-1.13/bin/kind

echo " done"
echo " "
echo "========================================================================"
echo " Install kubectl v1.16.4"
echo "========================================================================"
echo " "
echo " "

# DO NOT install the latest version, but the version 1.16.4 which is compliant 
# with kind v0.6.1

cp /vagrant/kubectl-v1.16.4-linux-amd64 /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

echo " done"
echo " "
echo "========================================================================"
echo " Update the PATH (in /etc/profile) for all users"
echo "========================================================================"
echo " "
echo " "

cat <<EOF >> /etc/profile

PATH=$PATH:/usr/lib/go-1.13/bin/
EOF
source /etc/profile


cat <<EOF >> /home/vagrant/.bashrc

PATH=$PATH:/usr/lib/go-1.13/bin/
EOF


# Deploy with kind a 3 nodes cluster, named "newyear"
echo "========================================================================"
echo "Installing a 3-nodes Kubernetes cluster (K8S-in-Docker)"
echo "========================================================================"
echo "..."

kind create cluster --config $cluster_configuration --name $cluster_name

echo "done"
echo "..."
echo " "

# Wait 5 seconds to give time for the nodes to get active and running
echo "..... wait 5 seconds ....."

sleep 5

echo "done"
echo "..."
echo " "


echo "========================================================================"
echo "Installing Kubernetes Dashboard"
echo "========================================================================"
echo "..."

# retrieve the yaml file with the proper version 
kubectl apply -f $dashboard_configuration

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "Create sample user with the right to access the dashboard"
echo "========================================================================"
echo "..."

kubectl apply -f $dasbboard_user

echo "done"
echo "..."
echo " "

# Wait 5 seconds to give time for the dashboard to be deployed and the user to 
# be created
echo "..... wait 5 seconds ....."

sleep 5

echo "done"
echo "..."
echo " "

# Grep the secret and use it to login on the browser
echo "========================================================================"
echo "Get Token"
echo "========================================================================"
echo "..."

admin_profile=$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
dashboard_token_full=$(kubectl -n kubernetes-dashboard describe secret $admin_profile | grep "token: ")
dashboard_token=${dashboard_token_full#"token: "}
touch "${dashboard_token_path}"
echo $dashboard_token > "${dashboard_token_path}"


echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "Start kube proxy in another tab of the existing terminal"
echo "========================================================================"
echo "..."

#gnome-terminal --tab -- kubectl proxy -p 8001

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "Launch dashboard in a web browser"
echo "========================================================================"
echo "..."

#xdg-open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

echo "Here is the token needed to log into the dashboard:"
cat "${dashboard_token_path}"

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "The END"
echo "========================================================================"
