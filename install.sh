#!/bin/bash

#
#  BEWARE : we assume that the install script was download with all the other
#           resources of the tutorial (cloned from github) and is locate on the
#           `learn-kubernetes` directory from where the tutorial will be run.
#


# This script will install `kind` v0.8.1 and `kubectl` v1.18.2, the versions on
# which the tutorial was built and tested. It requires `sudo` privilege to run:
#
#  $ sudo ./install.sh
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

# copy the sources from github

echo "======================================================================="
echo " Install kind and kubernetes"
echo "======================================================================="
echo "..."

cp ./deploy/kind-linux-amd64-v0.8.1 ./deploy/kind
chmod +x ./deploy/kind
mv ./deploy/kind /usr/local/bin/kind

cp ./deploy/kubectl-linux-amd64-v1.18.2 ./deploy/kubectl
chmod +x ./deploy/kubectl
mv ./deploy/kubectl /usr/local/bin/kubectl

echo "done"
echo "..."
echo " "

echo "========================================================================"
echo "The END"
echo "========================================================================"
