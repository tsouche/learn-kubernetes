#!/bin/bash

# This script assumes that both `kind` and `kubectl` have already beed installed
# with compatible versions.
#
# BEWARE - version compatibility matters!!!
#
# We assume here that we run `kind` v0.8.1 on `Kubernetes` v1.18.2, so you need
# to:
#   - install `kubectl` v1.18.2)
#       https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/linux/amd64/kubectl
#   - copy the dashboard YAML file v2.0.0 which is compatible with Kubernetes
#     v1.18:
#       https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

cluster_name="k8s-tuto"
deploy_directory="./cluster-deploy"
sandbox_directory="./sandbox"
cluster_configuration="kind-cluster.yaml"
dashboard_configuration="recommended.yaml"
dasbboard_user="dashboard-adminuser.yaml"
dashboard_token_path="data_dashboard_token"

echo "======================================================================="
echo " Create/populate the sandbox"
echo "======================================================================="
echo "..."

# check if a previous version of kubernetes configuration exist, and remove it
if [ -d "~/.kube" ]
then
  rm -rf ~/.kube
  mkdir /.kube
fi

# Create working copy files
# check if a previous version of the 'working' directory exist, and removes it
if [ -d $sandbox_directory ]
then
    rm -rf $sandbox_directory
fi
mkdir $sandbox_directory
cp $deploy_directory/kind-cluster-v0.2.yaml $sandbox_directory/$cluster_configuration
cp $deploy_directory/dashboard-v200-recommended.yaml $sandbox_directory/$dashboard_configuration
cp $deploy_directory/dashboard-adminuser.yaml $sandbox_directory/$dasbboard_user

cd $sandbox_directory

echo "done"
echo "..."
echo " "

# Deploy with kind a 3 nodes cluster, named "newyear"
echo "========================================================================"
echo "Installing a 5-nodes Kubernetes cluster (K8s-in-Docker)"
echo "========================================================================"
echo "..."

kind create cluster --config $cluster_configuration --name $cluster_name

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

#kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

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

gnome-terminal --tab -- kubectl proxy -p 8001

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "Launch dashboard in a web browser"
echo "========================================================================"
echo "..."

xdg-open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

echo "Here is the token needed to log into the dashboard:"
cat "${dashboard_token_path}"

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "The END"
echo "========================================================================"
