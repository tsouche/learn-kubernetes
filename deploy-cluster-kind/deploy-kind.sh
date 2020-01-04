#!/bin/bash


# indicate the dashboard version to collect on the kind official site
VERSION=v2.0.0-beta8


# BEWARE - version compatibility matters.
# Since kind is running on Kubernetes v1.16, I had to:
#   - install a compatible version of kubectl (1.16.4)
#   - copy the dashboard YAML file v2.0.0-beta8 which is compatible with 
#       Kubernetes v1.16
#       https://github.com/kubernetes/dashboard/releases/tag/v2.0.0-beta8



# Deploy with kind a 3 nodes cluster, named "newyear"
echo "========================================================================"
echo "Installing a 3-nodes Kubernetes cluster (K8S-in-Docker)"
echo "========================================================================"
echo "..."

kind create cluster --config ./kind-cluster.yaml --name newyear

echo "done"
echo "..."

# Wait 5 seconds to give time for the nodes to get active and running
echo "..... wait 5 seconds ....."

sleep 5

echo "done"
echo "..."


echo "========================================================================"
echo "Installing Kubernetes Dashboard"
echo "========================================================================"
echo "..."

# check if the dahsboard config file already exist, and remove it
if [ -f "./recommended.yaml"]
then
    rm ./recommended.yaml
fi
# retrieve the yaml file with the proper version 
curl -Lo ./recommended.yaml https://raw.githubusercontent.com/kubernetes/dashboard/$VERSION/aio/deploy/recommended.yaml

kubectl apply -f ./recommended.yaml

echo "done"
echo "..."

echo "========================================================================"
echo "Create sample user with the right to access the dashboard"
echo "========================================================================"
echo "..."

kubectl apply -f ./dashboard-adminuser.yaml

echo "done"
echo "..."

# Wait 5 seconds to give time for the dashboard to be deployed and the user to 
# be created
echo "..... wait 5 seconds ....."

sleep 5

echo "done"
echo "..."

# Grep the secret and use it to login on the browser
echo "========================================================================"
echo "Get Token"
echo "========================================================================"
echo "..."

kubectl -n kubernetes-dashboard describe secret "$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')"

echo "done"
echo "..."

echo "========================================================================"
echo "Start kube proxy in another tab of the existing terminal"
echo "========================================================================"
echo "..."

gnome-terminal --tab -- kubectl proxy -p 8001

echo "done"
echo "..."

echo "========================================================================"
echo "Launch dashboard in a web browser"
echo "========================================================================"
echo "..."

xdg-open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

echo "done"
echo "..."
