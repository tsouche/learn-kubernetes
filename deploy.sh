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
echo "======================================================================="
echo " Tutorial \"learn-kubernetes\" - Deploy a K8S-in-Docker cluster"
echo "======================================================================="
echo " "
echo " "
echo " "

echo "======================================================================="
echo " Cleanup the place"
echo "======================================================================="
echo "..."

source ./cluster-deploy/cluster-cleanup.sh

echo "done"
echo "..."
echo " "

echo "======================================================================="
echo " Create/populate the sandbox"
echo "======================================================================="
echo "..."

# Create working copy files
mkdir $sandbox_directory
cp $deploy_directory/$cluster_configuration \
   $deploy_directory/$ingress_configuration_crd \
   $deploy_directory/$ingress_configuration_operator \
   $deploy_directory/$dasbboard_user \
   $deploy_directory/$dashboard_configuration \
   $sandbox_directory

echo "done"
echo "..."
echo " "

# Deploy with kind a 3 nodes cluster, named "newyear"
echo "========================================================================"
echo "Installing a 5-nodes Kubernetes cluster (K8s-in-Docker)"
echo "========================================================================"
echo "..."

kind create cluster --config $sandbox_directory/$cluster_configuration --name $cluster_name

# Wait 5 seconds to give time for the nodes to get active and running
echo "..... wait 5 seconds ....."

sleep 5

echo "done"
echo "..."
echo " "


echo "========================================================================"
echo "Deploy an ingress controller"
echo "========================================================================"
echo "..."

kubectl apply -f $sandbox_directory/$ingress_configuration_crd
kubectl apply -n ambassador -f $sandbox_directory/$ingress_configuration_operator
kubectl wait --timeout=180s -n ambassador --for=condition=deployed ambassadorinstallations/ambassador

echo "..... wait 10 seconds ....."
sleep 10

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "Installing Kubernetes Dashboard"
echo "========================================================================"
echo "..."

# retrieve the yaml file with the proper version
kubectl apply -f $sandbox_directory/$dashboard_configuration
kubectl apply -f $sandbox_directory/$dasbboard_user
# Wait 5 seconds to give time for the dashboard to be deployed and the user to
# be created
echo "..... wait 5 seconds ....."
sleep 5
# Grep the secret and use it to login on the browser
admin_profile=$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
dashboard_token_full=$(kubectl -n kubernetes-dashboard describe secret $admin_profile | grep "token: ")
dashboard_token=${dashboard_token_full#"token: "}
echo $dashboard_token > $sandbox_directory/$dashboard_token_file_name
# apply an ingress to the dashboard
# kubectl apply -f $sandbox_directory/$dashboard_ingress

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "Launch dashboard in a web browser"
echo "========================================================================"
echo "..."

# Start kube proxy in another tab of the existing terminal"
gnome-terminal --quiet --tab -- kubectl proxy -p 8001

echo "Here is the token needed to log into the dashboard:"
echo $dashboard_token
echo " "
echo "You can copy this token in the Text Editor window, and paste it in the"
echo "browser, as a login token:"
# open the dashboard login page in a browser
xdg-open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
# open the text editor with the token ready to be printed
gedit --standalone $sandbox_directory/$dashboard_token_file_name &

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "The END"
echo "========================================================================"
