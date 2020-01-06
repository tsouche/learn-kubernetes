#!/bin/bash

echo " "
echo "======================================================================="
echo "|  Delete the cluster and clean temporary files                       |"
echo "======================================================================="
echo " "

cluster_name="newyear"
dashboard_configuration="./recommended.yaml"
dashboard_token_path="./data_dashboard_token"


echo "..."
echo " Remove the cluster"
echo "..."
echo " "

kind delete cluster --name $cluster_name


echo "..."
echo " Remove temporary files"
echo "..."
echo " "

# remove any previous version of kubernetes configuration files
rm -rf ~/.kube
# remove the dashboard configuration files
rm $dashboard_configuration
rm -rf $dashboard_token_path

echo "======================================================================="
echo " The END"
echo "======================================================================="
echo " "
