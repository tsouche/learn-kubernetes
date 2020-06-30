#!/bin/bash

# This script sets all required environment variables necessary to either
# deploy a kind cluster for this tutorial, or cleanup the cluster after the
# tutorial is completed.

export cluster_name="k8s-tuto"
export deploy_directory="./cluster-deploy"
export sandbox_directory="./sandbox"
export cluster_configuration="kind-cluster-v2.yaml"
export dashboard_configuration="dashboard-v200-recommended.yaml"
export dasbboard_user="dashboard-adminuser.yaml"
export dashboard_token_file_name="dashboard_token"
export ingress_configuration_crd="ambassador-operator-crds.yaml"
export ingress_configuration_operator="ambassador-operator-kind.yaml"
