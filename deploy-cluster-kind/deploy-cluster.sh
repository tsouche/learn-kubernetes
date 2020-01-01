#!/bin/bash
VERSION=v2.0.0-beta8


# BEWARE - version compatibility matters.
# Since kind is running on Kubernetes v1.15, I had to:
#   - install an older version of kubectl (1.15.17)
#       snap install kubectl --channel=1.15/stable
#   - copy the dashboard YAML file v2.0.0-beta4 which is compatible with 
#       Kubernetes v1.15:
#       * kubernetesui/dashboard:v2.0.0-beta4
#       * kubernetesui/metrics-scraper:v1.0.1
#       https://github.com/kubernetes/dashboard/releases/tag/v2.0.0-beta4


# Deploy with kind a 3 nodes cluster, named "newyear"
echo "======================================================="
echo "Installing a 3-nodes Kubernetes cluster (K8S-in-Docker)"
echo "======================================================="
echo "..."

kind create cluster --config kind-cluster.yaml --name newyear

echo "done"
echo "..."

# Wait 5 seconds to give time for the nodes to get active and running
echo "..... wait 5 seconds ....."

sleep 5

echo "done"
echo "..."


echo "==============================="
echo "Installing Kubernetes Dashboard"
echo "==============================="
echo "..."

# retrieve the yaml file with the proper version 
curl -Lo /projects/learn-kind/dashboard-$(echo $VERSION)-recommended.yaml https://raw.githubusercontent.com/kubernetes/dashboard/$VERSION/aio/deploy/recommended.yaml

kubectl apply -f /project/learn-kind/dashboard-$(echo $VERSION)-recommended.yaml

echo "done"
echo "..."

echo "========================================================="
echo "Create sample user with the right to access the dashboard"
echo "========================================================="
echo "..."

if [ -f /projects/learn-kind/dashboard-adminuser.yaml ]
then
    kubectl apply -f /projects/learn-kind/dashboard-adminuser.yaml
fi

echo "done"
echo "..."

# Wait 5 seconds to give time for the dashboard to be deployed and the user to 
# be created
echo "..... wait 5 seconds ....."

sleep 5

echo "done"
echo "..."

# Grep the secret and use it to login on the browser
echo "========="
echo "Get Token"
echo "========="
echo "..."

kubectl -n kubernetes-dashboard describe secret "$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')"

echo "done"
echo "..."

echo "========================================================"
echo "Start kube proxy in another tab of the existing terminal"
echo "========================================================"
echo "..."

gnome-terminal --tab -- kubectl proxy -p 8080

echo "done"
echo "..."

echo "================================="
echo "Launch dashboard in a web browser"
echo "================================="
echo "..."

xdg-open http://localhost:8080/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

echo "done"
echo "..."

