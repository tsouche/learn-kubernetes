#!/bin/bash

# This script will pass all the shell commands required in the Part 3 of the
# Tutorial. We assume that the cluster is up and running.

# Go to the tutorial directory
cd ~/learn-kubernetes/

# Deploy the first application
kubectl create deployment hello-part3 \
    --image=tsouche/learn-kubernetes:part3v1

# check the pods status
kubectl get pods

# check the deployment status
kubectl get deployments

# check the pods detailed status
kubectl get pods -o wide

# launch teh proxy in a new terminal tab
gnome-terminal bash --tab -- kubectl proxy -p 8001

# ping the API apiserver
curl http://localhost:8001/version

# store POD_NAME
export POD_NAME=$(kubectl get pods -o go-template \
    --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')

echo $POD_NAME

# check the application configuration
kubectl describe pods
kubectl get namespace
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/
kubectl logs $POD_NAME
kubectl exec $POD_NAME -- env
kubectl exec -ti $POD_NAME -- bash

# To be run inside the Pod:
#   cat app.py
#   curl localhost:80
#   exit

# create a new Kubernetes Service
kubectl get pods
kubectl get services
kubectl expose deployment/hello-part3 --type="NodePort" --port 80
kubectl get services
kubectl describe services/hello-part3

export NODE_PORT=30985
kubectl describe services/kubernetes
export ENDPOINT=172.18.0.5
curl $ENDPOINT:$NODE_PORT

# using labels
kubectl describe deployment
kubectl get pods -l app=hello
kubectl get services -l app=hello
export POD_NAME=$(kubectl get pods -o go-template \
    --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo $POD_NAME
kubectl label pod $POD_NAME version=v1
kubectl describe pods $POD_NAME
kubectl get pods -l version=v1

# delete everything
kubectl delete service -l app=hello
kubectl get services
curl $ENDPOINT:$NODE_PORT
kubectl exec -ti $POD_NAME -- curl localhost:80
kubectl expose deployment/hello --type="NodePort" --port 80
kubectl describe svc/hello
NODE_PORT=32731
curl $ENDPOINT:$NODE_PORT
