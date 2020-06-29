#!/bin/bash

# deploy the frontend
kubectl apply -f ./app-part4/webserver-deployment.yaml
kubectl get pods -o wide --watch
# expose the frontend as a Service
kubectl apply -f ./app-part4/webserver-service.yaml

# check the app without redis backend (replace with the real values obtained above)
kubectl get service webserver
kubectl describe service kubernetes
curl 172.18.0.5:32112
kubectl apply -f ./app-part4/webserver-ingress.yaml
curl localhost/part4

# deploy the backend master
kubectl apply -f ./app-part4/redis-master-deployment.yaml
kubectl get pods -o wide --watch
kubectl apply -f ./app-part4/redis-master-service.yaml
# deploy the backend slave
kubectl apply -f ./app-part4/redis-slave-deployment.yaml
kubectl get pods -o wide --watch
kubectl apply -f ./app-part4/redis-slave-service.yaml

# check again the app with redis backend
curl localhost/part4

# check the effect of labels
kubectl get pods -l application=hello-world-part4 -o wide
kubectl get pods -l tier=frontend -o wide
kubectl get pods -l tier=backend -o wide
kubectl get pods -l component=webserver -o wide
kubectl get pods -l component=redis-master -o wide
kubectl get pods -l component=redis-slave -o wide

# check resilience against the loss of a Pod and Node
