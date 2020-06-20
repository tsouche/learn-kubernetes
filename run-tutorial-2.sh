#!/bin/bash

# This script will pass all teh shell commands required in the Part 2 of the
# Tutorial.

# deploy the Kind cluster
d ~/learn-kubernetes/
./deploy.sh

# check teh cluster status
kind get clusters
kubectl get nodes
