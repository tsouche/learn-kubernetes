#!/bin/bash

# read the environment variables
source ./cluster-deploy/cluster-variables.sh

# cleanup the files in the sandbox
if [ -d $sandbox_directory ]
then
    rm -rf $sandbox_directory
fi

# This script will cleanup the cluster after the tutorial is completed.
kind delete cluster --name $cluster_name

# check if a previous version of kubernetes configuration exist, and remove it
if [ -d "~/.kube" ]
then
  rm -rf ~/.kube
  mkdir /.kube
fi
