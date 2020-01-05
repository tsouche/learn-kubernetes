#!/bin/bash


# indicate the dashboard version to collect on the kind official site
VERSION=v2.0.0-beta8


# BEWARE - version compatibility matters.
# Since kind is running on Kubernetes v1.16, I had to:
#   - install a compatible version of kubectl (1.16.4)
#   - copy the dashboard YAML file v2.0.0-beta8 which is compatible with 
#       Kubernetes v1.16
#       https://github.com/kubernetes/dashboard/releases/tag/v2.0.0-beta8

cluster_configuration="./kind-cluster.yaml"
cluster_name="newyear"
dashboard_configuration="./recommended.yaml"
dasbboard_user="./dashboard-adminuser.yaml"
dashboard_token_path="./data_dashboard_token"

echo "======================================================================="
echo " Remove temporary files"
echo "======================================================================="
echo "..."

# check if a previous version of kubernetes configuration exist, and remove it
if [ -d "~/.kube" ]
then
    rm -rf ~/.kube
    mkdir /.kube
fi
# check if the dahsboard configuration exist, and remove it
if [ -f $dashboard_configuration ]
then
    rm $dashboard_configuration
fi
if [ -f $dashboard_token_path ]
then
    rm -rf $dashboard_token_path
fi

echo "done"
echo "..."
echo " "



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
curl -Lo $dashboard_configuration https://raw.githubusercontent.com/kubernetes/dashboard/$VERSION/aio/deploy/recommended.yaml

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
