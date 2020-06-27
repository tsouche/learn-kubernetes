#!/bin/bash

# deploy the frontend
kubectl apply -f ./app-part4/webserver-deployment.yaml
kubectl get deployment
kubectl get pods -o wide
# expose the frontend as a Service
kubectl apply -f ./app-part4/webserver-service.yaml
kubectl get service
kubectl get pds -o wide

# check the public server port
kubectl describe service webserver
# check the public server ip
kubectl describe service kubernetes
# check the app without redis backend (replace with the real values obtained above)
curl 172.18.0.5:32112

# deploy the backend
kubectl apply -f ./app-part4/redis-master-deployment.yaml
kubectl get deployment
kubectl get pods -o wide
# expose the backend
kubectl apply -f ./app-part4/redis-master-service.yaml
kubectl get service
kubectl get pods -o wide

# check again the app with redis backend
curl 172.18.0.5:32112


kubectl get pods -l application=hello-world-part4 -o wide
kubectl get pods -l tier=frontend -o wide
kubectl get pods -l tier=backend -o wide
kubectl get pods -l component=webserver -o wide
kubectl get pods -l component=redis-master -o wide
