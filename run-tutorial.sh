#!/bin/bash

# This script will pass all the shell commands required in the Tutorial.
# We assume that the cluster is up and running.


###############################################################################
## PART 3
###############################################################################


# Go to the tutorial directory
cd /tuto/learn-kubernetes/

# Deploy the first application
kubectl create deployment hello-part3 --image=tsouche/learn-kubernetes:part3v1

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
kubectl get pods -l app=hello-part3
kubectl get services -l app=hello-part3
export POD_NAME=$(kubectl get pods -o go-template \
    --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo $POD_NAME
kubectl label pod $POD_NAME version=v1
kubectl describe pods $POD_NAME
kubectl get pods -l version=v1

# delete everything
kubectl delete service -l app=hello-part3
kubectl get services
curl $ENDPOINT:$NODE_PORT
kubectl exec -ti $POD_NAME -- curl localhost:80
kubectl expose deployment/hello --type="NodePort" --port 80
kubectl describe svc/hello-part3
export NODE_PORT=30558
curl $ENDPOINT:$NODE_PORT

# scale up your app
kubectl get deployments
kubectl scale deployments/hello-part3 --replicas=4
kubectl get deployments
kubectl get pods -o wide
kubectl describe deployments/hello-part3
kubectl describe services/hello-part3
curl $ENDPOINT:$NODE_PORT

# scale down your app
kubectl scale deployments/hello-part3 --replicas=2
kubectl get deployments
kubectl get pods -o wide

# update the version of the app
kubectl get deployments
kubectl describe pods
kubectl get pods -o wide

# verify the update
kubectl describe services/hello-part3
curl $ENDPOINT:$NODE_PORT
kubectl rollout status deployments/hello-part3
kubectl describe deployment/hello-part3

# rollback the update
kubectl set image deployment/hello-part3 learn-kubernetes=tsouche/learn-kubernetes:part3v10
kubectl get deployments
kubectl get pods -o wide
kubectl describe pods
kubectl rollout undo deployments/hello-part3
kubectl get deployments
kubectl get pods -o wide
kubectl describe pods

# expose your app even more publicly
kubectl delete service hello-part3
kubectl delete deployment hello-part3
kubectl apply -f ./app-part3/webserver-deployment-v1.yaml
kubectl describe deployment hello-part3-deployment
kubectl get pods -o wide --watch
kubectl apply -f ./app-part3/webserver-service.yaml
kubectl describe service hello-part3-service
kubectl apply -f ./app-part3/webserver-ingress.yaml
kubectl describe ingress hello-part3-ingress
curl localhost/part3
kubectl apply -f ./app-part3/webserver-deployment-v2.yaml
kubectl describe deployment hello-part3-deployment
kubectl get pods -o wide --watch
curl localhost/part3


###############################################################################
## PART 4
###############################################################################

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

# check again the app with redis backend
curl localhost/part4

# check the effect of labels
kubectl get pods -l application=hello-world-part4 -o wide
kubectl get pods -l tier=frontend -o wide
kubectl get pods -l tier=backend -o wide
kubectl get pods -l component=webserver -o wide
kubectl get pods -l component=redis-master -o wide


# deploy everythin in one go
kubectl apply -f ./app-part4/webserver-deployment.yaml && \
  kubectl apply -f ./app-part4/webserver-service.yaml && \
  kubectl apply -f ./app-part4/webserver-ingress.yaml && \
  kubectl apply -f ./app-part4/redis-master-deployment.yaml && \
  kubectl apply -f ./app-part4/redis-master-service.yaml && \
  kubectl get pods -o wide --watch


# check resilience against the loss of a Pod and Node




###############################################################################
## PART 5
###############################################################################
