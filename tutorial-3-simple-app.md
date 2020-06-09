# Part 3 - Deploy a simple app

# BESOIN DE DECRIRE COMMENT FAIRE LE TUTO AVEC KIND:
#  - comment lancer le cluster
#  - où aller pour trouver le dashboard
#  - comment lancer/arrêter le proxy

# BESOIN DE REVOIR TOUTES LES COMMANDES ET IMAGES:
#  - hypothese 1: seul scénario = kind
#  - hypothèse 2: prompt = "tuto@laptop:~$"


## 1 - Kubernetes Deployments

Once you have a running Kubernetes cluster, you can deploy your containerized applications on top of it. To deploy your containerized application on top of the cluster, you create what is called a ***Kubernetes Deployment***. The Deployment materializes through a text file (a YAML file) which defines the *target state* of your application (which Docker container or which set of containers will compose your application, on how many nodes - in order to bring resilience - or other criterias your application should respect once it is actually deployed on the cluster).
This text file instructs Kubernetes how to create and update instances of your application: actually,
* it tells the **Controller Manager** to spawn a **Deployment Controller**
* this newly created Deployment Controller will have as first task to read this text file and tell the **Scheduler** the technical rules which should be respected when 'scheduling' the pods onto individual Nodes in the cluster,
* and the Scheduler will actually find the appropriate Nodes and assign the pods (which carry the containers composing your application).

![alt txt](./images/tuto-3-app-deployment.png "Kubernetes Master schedules Pods on Nodes")

Once the application instances are created, the Deployment Controller continuously *monitors* those instances (i.e. it will monitors the changes in any resources allocated to the application it is in charge of: Nodes, network, storage, pods...). If the Node hosting an instance goes down or is deleted, the Deployment controller replaces the instance with an instance on another Node in the cluster. This provides a self-healing mechanism to address machine failure or maintenance: since the text file describes the *desired target state* of the deployment, the Deployment controller actually detects that there is a deviation of the real deployment vs. the described target, and it reacts by deploying new pods to available nodes in order to get bask to the *desired state*.

In a pre-orchestration world, installation scripts would often be used to start applications, but they did not allow recovery from machine failure since there was little way to actually monitor the status of the application. By both creating your application instances and keeping them running across Nodes, Kubernetes Deployments provide a fundamentally different approach to application management.

## 2 - Deploying your first app on Kubernetes

You can create and manage a Deployment by using the Kubernetes command line interface, `kubectl`. `kubectl` uses the Kubernetes API to interact with the cluster: its role is actually to translate commands which you enter (or more often YAML files containing your instructions) into API calls to the Kubernetes API server. It actually does *nothing*: it only passes your instructions to the Master via the API server, and translate the answers into a human readable format.
![alt txt](./images/tuto-3-kubectl-kubernetes-api.png "Kubectl accesses Kubernetes via the API server")

 In this module, you'll learn the most common `kubectl` commands needed to create *Deployments* that run your applications on a Kubernetes cluster.

When you create a *Deployment*, you'll need to specify the container image for your application and the number of replicas that you want to run. You can change that information later by updating your Deployment (i.e. updating the YAML file and passing it yo `kubectl`); sections 5 and 6 of this tutorial discuss how you can scale and update your *Deployments*.

Applications need to be packaged into one of the supported container formats in order to be deployed on Kubernetes: here we will use **Docker**.

For your first Deployment, you'll use a simple Python application, derived from the one used in the *docker-get-started* tutorial. The docker image is available from DockerHub under my public repository, with the name 'learn-kubernetes' and the tag 'part3':

Let’s deploy this first app on Kubernetes with the `kubectl create deployment` command. We need to provide the deployment name and app image location (include the full repository url if the container images are hosted outside Docker hub):
```
tuto@laptop:~$ kubectl create deployment hello --image=tsouche/learn-kubernetes:part3
deployment.apps/hello created
```
***Great!*** You just deployed your first application by creating a deployment (which you can also see in the dashboard:

***image to be replaced !!!***
![alt txt](./images/tuto-3-dashboard-deployment-first.png "your first deployment on Kubernetes!!!").

You can also see that it created a Pod called `hello-7747bc55f-p486h` as it is visible on the dashboard:

***image to be replaced !!!***
![alt txt](./images/tuto-3-dashboard-pod-bootcamp.png "your first deployment on Kubernetes!!!").


You can see the same information in the terminal:
```
tutoo@laptop:/projects/kind$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE             NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running   0          28s   10.244.1.2   newyear-worker   <none>           <none>
```
In few seconds, the application is deployed.

> Note: from now on, we assume that you will go frequently on the dashboard to check the changes happening on the cluster, and we will focus the tutorial on the CLI commands and results as they appear in the terminal. Again, the purpose of this tutorial is solely to get you aquainted with the Kubernetes concepts and to manipulate the cluster, while you may get far more efficient at manipulating directly the REST APIs or managing some actions via the dashboard itself.
> So, as of now, we will not mention directly screenshots related to the progress on the tutorial, but you may see more screenshots in the `./images` directory.

This `kubectl create deployment` command performed a few things for you:
* searched for a suitable node where an instance of the application could be run (we have only 1 available node)
* scheduled the application to run on that Node
* configured the cluster to reschedule the instance on a new Node when needed

To list your deployments use the `kubectl get deployments` command:
```
tuto@laptop:/projects/kind$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   1/1     1            1           42s
```

Let's details this line since you will see later in the tutorial many results
similar to this one:
* The `1/1` means `1 ready for 1 Desired`: 1 ready is the number of pod active (with  the container which is mentioned in the YAML file) and the YAML file specifies that we should always have 1 instance running.
* The `1 UP-TO-DATE` means that the one active is of the right version: there is consequently no need for Kubernetes to update the Pod with a fresher version.
* The `1 AVAILABLE` means that 1 instance of the Pod is actually available to the end-users (and there could be many reasons for which the Pod would not be available: for instance, the network could be down for a part of the cluster, thus the corresponding Node would be isolated, and Kubernetes would have to spawn a new instance of the Pod on another Node with good connectivity, in order to secure that the end-users keep having 1 instance truely available to them).

We can see here that there is 1 deployment, running 1 single instance of your app. The instance is running inside a Docker container on one of the nodes. To get more details, we expand the results of the `kubectl get pods` command: we can see that this Pod is running on the slave 1.
```
tuto@laptop:/projects/kind$ kubectl get pods
*** insert the result here ***
```

## 3 - Connecting to your app from within the cluster

Pods that are running inside Kubernetes are running on a private, isolated network. By default they are visible from other pods and services within the same kubernetes cluster, but not outside that network. When we use `kubectl`, we're interacting through an API endpoint to communicate with our application.

We will cover other options on how to expose your application outside the kubernetes cluster in the later section. For the moment, we will still use the proxy that will forward communications into the cluster-wide, private network. The proxy can be terminated by pressing `Ctl-C` and won't show any output
while its running.

If you terminated the proxy, we will restart it in a second terminal tab:
```
tuto@laptop:~$ gnome-terminal bash --tab -- kubectl proxy -p 8001
Starting to serve on 127.0.0.1:8001
```
The proxy enables direct access to the API from these terminals: you can see all those APIs hosted through the proxy endpoint. For example, we can query the version directly through the API using the curl command: *** mettre à jour avec la version 1.18 de Kubernetes !!!***
```
tuto@laptop:~$ curl http://localhost:8001/version
{
  "major": "1",
  "minor": "16",
  "gitVersion": "v1.16.3",
  "gitCommit": "b3cbbae08ec52a7fc73d334838e18d17e8512749",
  "gitTreeState": "clean",
  "buildDate": "2019-12-04T07:23:47Z",
  "goVersion": "go1.12.12",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```
If Port 8001 is not accessible, ensure that the `kubectl proxy` started above is running.

The API server will automatically create an endpoint for each pod, based on the pod name, that is also accessible through the proxy.

First we need to get the Pod name, and we'll store in the environment variable `POD_NAME`:
```
tuto@laptop:~$ export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
tuto@laptop:~$ echo $POD_NAME
hello-5bfc654f49-bvbw5
```
In order for the new deployment to be accessible without using the Proxy, a 'Service' is required which will be explained in the next modules.


## 4 - Explore your app

### 4.1 - Kubernetes Pods

When you created a *Deployment* in Section 2, Kubernetes created a Pod to host your application instance. A Pod is a Kubernetes abstraction that represents a group of one or more application containers, and some shared resources for those containers. Those resources include:
* Shared storage, as Volumes
* Networking, as a unique cluster IP address
* Information about how to run each container, such as the container image version or specific ports to use

A Pod models an application-specific *logical host* and can contain different application containers which are relatively tightly coupled. For example, a Pod might include both the container with your Node.js app as well as a different container that feeds the data to be published by the Node.js webserver. The containers in a Pod share the same IP Address and port space, are always co-located and co-scheduled, and run in a shared context on the same Node.

As explained in Part 1, Pods are the atomic unit on the Kubernetes platform.

### 4.2 - Nodes

A Pod always runs on a Node. A Node is a worker machine in Kubernetes and may be either a virtual or a physical machine, depending on the cluster. Each Node is managed by the Master. A Node can have multiple pods, and the Kubernetes Master automatically handles scheduling the pods across the Nodes in the cluster. The Master's automatic scheduling takes into account the available resources on each Node.

Every Kubernetes Node runs at least:
* `Kubelet`, a process responsible for communication between the Kubernetes Master and the Node; it manages the Pods and the containers running on a machine.
* A container runtime (like `Docker`, `rkt`) responsible for pulling the container image from a registry, unpacking the container, and running the application.

![alt txt](./images/tuto-1-node-overview.png "Node overview")

Containers should only be scheduled together in a single Pod if they are tightly coupled and need to share resources such as disk.



4.3 - Check the application configuration
=========================================

We already have checked the pods with `kubectl`, so we know that a `kubernetes-bootcamp` pod runs on the `slave 2`. Now, let's view what containers are inside that Pod and what images are used to build those containers. To do so, we run the describe pods command:
```
tuto@laptop:~$ kubectl describe pods
Name:         hello-5bfc654f49-bvbw5
Namespace:    default
Priority:     0
Node:         newyear-worker/172.17.0.2
Start Time:   Wed, 01 Jan 2020 16:21:15 +0100
Labels:       app=hello
              pod-template-hash=5bfc654f49
Annotations:  <none>
Status:       Running
IP:           10.244.1.2
IPs:
  IP:           10.244.1.2
Controlled By:  ReplicaSet/hello-5bfc654f49
Containers:
  learn-kubernetes:
    Container ID:   containerd://1efd70fa3f226739dd4a4f264327496eb2195a6c1399d6d2bcd1ce08143d1d48
    Image:          tsouche/learn-kubernetes:part3
    Image ID:       docker.io/tsouche/learn-kubernetes@sha256:ba5e8b3f6868f7e3753d53227a1ec7032f1c9fb5749b54d147ae3729f11f170c
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Wed, 01 Jan 2020 16:21:38 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-wtrfg (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-wtrfg:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-wtrfg
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age   From                     Message
  ----    ------     ----  ----                     -------
  Normal  Scheduled  2m5s  default-scheduler        Successfully assigned default/hello-5bfc654f49-bvbw5 to newyear-worker
  Normal  Pulling    2m4s  kubelet, newyear-worker  Pulling image "tsouche/learn-kubernetes:part3"
  Normal  Pulled     105s  kubelet, newyear-worker  Successfully pulled image "tsouche/learn-kubernetes:part3"
  Normal  Created    102s  kubelet, newyear-worker  Created container learn-kubernetes
  Normal  Started    102s  kubelet, newyear-worker  Started container learn-kubernetes
```

Whaou... Plenty of information is available, as you can see: IP address, the ports used and a list of events related to the lifecycle of the Pod.

The output of the describe command is extensive and covers some concepts that we didn’t explain yet, but don’t worry, they will become familiar by the end of this bootcamp.

> Note: the `describe` command can be used to get detailed information about most of the kubernetes primitives: node, pods, deployments. The describe output is designed to be human readable, not to be scripted against.


### 4.4 - Show the app in the terminal

Recall that Pods are running in an isolated, private network - so we continue with the `kubectl proxy` command in a second terminal window (on port 8001).

You have store the Pod name in the `POD_NAME` environment variable.

To see the output of our application, run a `curl` request.
```
tuto@laptop:~$ kubectl get namespace
NAME                   STATUS   AGE
default                Active   10m
kube-node-lease        Active   10m
kube-public            Active   10m
kube-system            Active   10m
kubernetes-dashboard   Active   8m55s

tuto@laptop:~$ curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "hello-5bfc654f49-bvbw5",
    "generateName": "hello-5bfc654f49-",
    "namespace": "default",
    "selfLink": "/api/v1/namespaces/default/pods/hello-5bfc654f49-bvbw5",
    "uid": "7a02f865-e0cf-4f29-90c1-a4c059f38e8b",
    "resourceVersion": "964",
    "creationTimestamp": "2020-01-01T15:21:15Z",
    "labels": {
      "app": "hello",
      "pod-template-hash": "5bfc654f49"
    },
    "ownerReferences": [
      {
        "apiVersion": "apps/v1",
        "kind": "ReplicaSet",
        "name": "hello-5bfc654f49",
        "uid": "7db64fda-51dc-4d9a-82fc-05fc2cdc822e",
        "controller": true,
        "blockOwnerDeletion": true
      }
    ]
  },
  "spec": {
    "volumes": [
      {
        "name": "default-token-wtrfg",
        "secret": {
          "secretName": "default-token-wtrfg",
          "defaultMode": 420
        }
      }
    ],
    "containers": [
      {
        "name": "learn-kubernetes",
        "image": "tsouche/learn-kubernetes:part3",
        "resources": {

        },
        "volumeMounts": [
          {
            "name": "default-token-wtrfg",
            "readOnly": true,
            "mountPath": "/var/run/secrets/kubernetes.io/serviceaccount"
          }
        ],
        "terminationMessagePath": "/dev/termination-log",
        "terminationMessagePolicy": "File",
        "imagePullPolicy": "IfNotPresent"
      }
    ],
    "restartPolicy": "Always",
    "terminationGracePeriodSeconds": 30,
    "dnsPolicy": "ClusterFirst",
    "serviceAccountName": "default",
    "serviceAccount": "default",
    "nodeName": "newyear-worker",
    "securityContext": {

    },
    "schedulerName": "default-scheduler",
    "tolerations": [
      {
        "key": "node.kubernetes.io/not-ready",
        "operator": "Exists",
        "effect": "NoExecute",
        "tolerationSeconds": 300
      },
      {
        "key": "node.kubernetes.io/unreachable",
        "operator": "Exists",
        "effect": "NoExecute",
        "tolerationSeconds": 300
      }
    ],
    "priority": 0,
    "enableServiceLinks": true
  },
  "status": {
    "phase": "Running",
    "conditions": [
      {
        "type": "Initialized",
        "status": "True",
        "lastProbeTime": null,
        "lastTransitionTime": "2020-01-01T15:21:15Z"
      },
      {
        "type": "Ready",
        "status": "True",
        "lastProbeTime": null,
        "lastTransitionTime": "2020-01-01T15:21:39Z"
      },
      {
        "type": "ContainersReady",
        "status": "True",
        "lastProbeTime": null,
        "lastTransitionTime": "2020-01-01T15:21:39Z"
      },
      {
        "type": "PodScheduled",
        "status": "True",
        "lastProbeTime": null,
        "lastTransitionTime": "2020-01-01T15:21:15Z"
      }
    ],
    "hostIP": "172.17.0.2",
    "podIP": "10.244.1.2",
    "podIPs": [
      {
        "ip": "10.244.1.2"
      }
    ],
    "startTime": "2020-01-01T15:21:15Z",
    "containerStatuses": [
      {
        "name": "learn-kubernetes",
        "state": {
          "running": {
            "startedAt": "2020-01-01T15:21:38Z"
          }
        },
        "lastState": {

        },
        "ready": true,
        "restartCount": 0,
        "image": "docker.io/tsouche/learn-kubernetes:part3",
        "imageID": "docker.io/tsouche/learn-kubernetes@sha256:ba5e8b3f6868f7e3753d53227a1ec7032f1c9fb5749b54d147ae3729f11f170c",
        "containerID": "containerd://1efd70fa3f226739dd4a4f264327496eb2195a6c1399d6d2bcd1ce08143d1d48",
        "started": true
      }
    ],
    "qosClass": "BestEffort"
  }
}
```
Pretty verbose, huh...
At least, it enables to demonstrate that we can access the cluster from the host machine, and poll directly the REST APIs to retrieve information about the currently deployed applications. Interestingly, doing so manually, we operate exactly the same way `kubectl` or the dashboard do: they poll the REST APIs exposed by the cluster.

The url structure is self explicit:
* it specifies the API version (v1 since versions 1.15 at least)
* it then indicated the namespaces (here: `default`)
* and then indicates the resource we need to poll (pods, deployment...).

In our case, we indicate 'pods' and which Pod (with its name) we want information on.


### 4.5 - View the container logs

Anything that the application would normally send to `STDOUT` becomes logs for the container within the Pod. We can retrieve these logs using the `kubectl logs` command:
```
tuto@laptop:~$ kubectl logs $POD_NAME
 * Serving Flask app "app" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
```

We can see everything that the application sent to `stdout`, because we have not set a proper `syslog` in the app or in the container. Obviously, in a real environment, the logs would be sent towards a syslog agent, and Kubernetes would then manage the redirection of the logs to the log management system (outside Kubernetes).


### 4.6 - Executing command inside the container

We can execute commands directly in the container once the Pod is up and running. For this, we use the `exec command` and use the name of the Pod as a parameter. Let’s list the environment variables:
```
tuto@laptop:~$ kubectl exec $POD_NAME env
PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=hello-5bfc654f49-bvbw5
LANG=C.UTF-8
GPG_KEY=0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
PYTHON_VERSION=3.6.9
PYTHON_PIP_VERSION=19.3.1
PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/ffe826207a010164265d9cc807978e3604d18ca0/get-pip.py
PYTHON_GET_PIP_SHA256=b86f36cc4345ae87bfd4f10ef6b2dbfa7a872fbff70608a1e43944d283fd0eee
NAME=World
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.96.0.1:443
HOME=/root
```

Again, worth mentioning that the name of the container itself can be omitted since we only have a single container in the Pod.

Next let’s start a bash session in the Pod’s container:
```
tuto@laptop:~$ kubectl exec -ti $POD_NAME bash
root@hello-5bfc654f49-bvbw5:/app#
```
We have now an open console on the container where we run our Python application, and we are logged as root. The source code of the app is in the `app.py` file:
```
  root@hello-5bfc654f49-bvbw5:/app# cat app.py
  from flask import Flask
  import os
  import socket

  app = Flask(__name__)

  @app.route("/")
  def hello():
      html = "<h3>Hello {name}!</h3>" \
             "<b>Hostname:</b> {hostname}<br/>"
      return html.format(name=os.getenv("NAME", "world"), hostname=socket.gethostname())

  if __name__ == "__main__":
      app.run(host='0.0.0.0', port=80)
```

You can check that the application is up by running a `curl` command:
```
root@hello-5bfc654f49-bvbw5:/app# curl localhost:80
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-bvbw5<br/>
```
> Note: here we used `localhost:80` because we executed the command inside the container inside the Pod. Outside the container, the port 8001 is exposed. If you cannot connect to localhost:80, check to make sure you have run the `kubectl exec command` and are launching the command from within the Pod

To close your container connection type "exit".
```
root@hello-5bfc654f49-bvbw5:/app# exit
exit
tuto@laptop:~$
```

## 5 - Expose Your App Publicly


### 5.1 - Overview of Kubernetes Services

Kubernetes Pods are mortal. Pods in fact have a lifecycle. When a worker node dies, the Pods running on the Node are also lost. A `ReplicaSet` might then dynamically drive the cluster back to desired state via creation of new Pods to keep your application running. As another example, consider an image-processing backend with 3 replicas. Those replicas are exchangeable; the front-end system should not care about backend replicas or even if a Pod is lost and recreated. That said, each Pod in a Kubernetes cluster has a unique IP address, even Pods on the same Node, so there needs to be a way of automatically reconciling changes among Pods so that your applications continue to function.

A `Service` in Kubernetes is an abstraction which defines a logical set of Pods and a policy by which to access them. Services enable a loose coupling between dependent Pods. A Service is defined using `YAML` (preferred) or `JSON`, like all Kubernetes objects. The set of Pods targeted by a Service is usually determined by a `LabelSelector`: a `LabelSelector` is a the usual way Kubernetes will identify the right pods.

Although each Pod has a unique IP address, those IPs are not exposed outside the cluster without a `Service`. `Services` allow your applications to receive traffic (from outside or from other applications runnig on the same cluster). `Services` can be exposed in different ways by specifying a type in the `ServiceSpec`:
* #### ClusterIP (default)
Exposes the `Service` on an internal IP in the cluster. This type makes the Service only reachable from within the cluster, by other services running on the same cluster.
* #### NodePort
Exposes the Service on the same port of each selected Node in the cluster using NAT. Makes a Service accessible from outside the cluster using `<NodeIP>:<NodePort>`.
The principle here is that the `<NodeIP>` is shared by all services running on the same cluster: they only differentiate one from another by their port number. This is very convenient to enable a controlled communication between services, typically when they should primarily get exposed via an API gateway which will handle security and access rights.
* #### LoadBalancer
Creates an external load balancer in the current cloud (if supported) and assigns a fixed, external IP to the Service.
Here, the service has its own IP and its own (set of) port(s): it is very easily reacheable from outside the cluster, which implies that it must embed security by design.
* ### ExternalName
Exposes the Service using an arbitrary name (specified by `externalName` in the spec) by returning a `CNAME` record with the name. No proxy is used.


Additionally, note that there are some use cases with `Services` that involve not defining selector in the spec. A `Service` created without selector will also not create the corresponding Endpoints object. This allows users to manually map a `Service` to specific `endpoints`. Another possibility why there may be no selector is you are strictly using type: `ExternalName`.


### 5.2 - Services and Labels


![alt txt](./images/tuto-3-expose-your-app-services-and-labels-1.png "Use a 'Service' to expose your app")

A `Service` routes traffic across a set of Pods. `Services` are the abstraction that allow pods to die and replicate in Kubernetes without impacting your application. Discovery and routing among dependent Pods (such as the frontend and backend components in an application) is handled by Kubernetes Services.

Services match a set of Pods using `labels` and `selectors`, a grouping primitive that allows logical operation on objects in Kubernetes. `Labels` are key/value pairs attached to objects and can be used in any number of ways:
* Designate objects for development, test, and production
* Embed version tags
* Classify an object using tags

    ![alt txt](./images/tuto-3-expose-your-app-services-and-labels-2.png)

Labels can be attached to objects at creation time or later on. They can be modified at any time. Let's expose our application now using a Service and apply some labels.


5.3 - Create a new service
==========================


Let’s verify that our application is running. We’ll use the 'kubectl get'
command and look for existing Pods:

tuto@laptop:~$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
hello-5bfc654f49-bvbw5   1/1     Running   0          8m

Next, let’s list the current Services from our cluster:

tuto@laptop:~$ kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   12m

We have a 'Service' called kubernetes that is created by default when the
cluster starts. To create a new service and expose it to external traffic
we’ll use the 'expose' command with 'NodePort' as parameter.

tuto@laptop:~$ kubectl expose deployment/hello --type="NodePort" --port 80
service/hello exposed

Let’s run again the get services command:

tuto@laptop:~$ kubectl get services
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
hello        NodePort    10.96.206.27   <none>        80:31100/TCP   5s
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        12m

Yes: we have now a running Service called 'hello'. Here we see that the
Service received a unique cluster-IP, an internal port and no external-IP
(the shared IP of the cluster must be used to access it).

To find out what port was opened externally (by the NodePort option) we’ll run
the describe service command:

tuto@laptop:~$ kubectl describe services/hello
Name:                     hello
Namespace:                default
Labels:                   app=hello
Annotations:              <none>
Selector:                 app=hello
Type:                     NodePort
IP:                       10.96.206.27
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31100/TCP
Endpoints:                10.244.1.2:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

We ceate an environment variable called NODE_PORT that has the value of the
Node port assigned:

tuto@laptop:~$ export NODE_PORT=31100

Then we need to identify the external IP which is exposed for the whole
cluster: this ip is used as the 'endpoint' for the default 'kubernetes'
service:

tuto@laptop:~$ kubectl describe services/kubernetes
Name:              kubernetes
Namespace:         default
Labels:            component=apiserver
                   provider=kubernetes
Annotations:       <none>
Selector:          <none>
Type:              ClusterIP
IP:                10.96.0.1
Port:              https  443/TCP
TargetPort:        6443/TCP
Endpoints:         172.17.0.3:6443
Session Affinity:  None
Events:            <none>

Here we can see the cluster's shared Endpoint: 172.17.0.3.

tuto@laptop:~$ export ENDPOINT=172.17.0.3

Now that we have both the ip@ (172.17.0.3) and the port (31100), we can test
that the app is exposed outside of the cluster using curl:

tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-bvbw5<br/>
tuto@laptop:~$

And we get a response from the server. The Service is exposed.


5.4 - Using labels
==================

The Deployment created automatically a label for our Pod. With describe
deployment command, you can see the name of the label:

tuto@laptop:~$ kubectl describe deployment
Name:                   hello
Namespace:              default
CreationTimestamp:      Wed, 01 Jan 2020 16:21:15 +0100
Labels:                 app=hello
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=hello
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=hello
  Containers:
   learn-kubernetes:
    Image:        tsouche/learn-kubernetes:part3
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   hello-5bfc654f49 (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  10m   deployment-controller  Scaled up replica set hello-5bfc654f49 to 1


As you can see, the label is 'app' and its value is 'hello', so it appears as
'app=hello'. Let’s use this label to query our list of Pods. We’ll use the
kubectl get pods command with -l as a parameter, followed by the label values:

tuto@laptop:~$ kubectl get pods -l app=hello
NAME                     READY   STATUS    RESTARTS   AGE
hello-5bfc654f49-bvbw5   1/1     Running   0          11m


You can do the same to list the existing services:

tuto@laptop:~$ kubectl get services -l app=hello
NAME    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
hello   NodePort   10.96.206.27   <none>        80:31100/TCP   2m59s


Get the name of the Pod and store it in the POD_NAME environment variable:

tuto@laptop:~$ export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
tuto@laptop:~$ echo $POD_NAME
hello-5bfc654f49-bvbw5

To apply a new label we use the label command followed by the object type,
object name and the new label: we create the label 'version' and we assign it
a value of 'v1'.

tuto@laptop:~$ kubectl label pod $POD_NAME version=v1
pod/hello-5bfc654f49-bvbw5 labeled


This will apply a new label to our Pod (we pinned the application version to
the Pod), and we can check it with the describe pod command:

tuto@laptop:~$ kubectl describe pods $POD_NAME
Name:         hello-5bfc654f49-bvbw5
Namespace:    default
Priority:     0
Node:         newyear-worker/172.17.0.2
Start Time:   Wed, 01 Jan 2020 16:21:15 +0100
Labels:       app=hello
              pod-template-hash=5bfc654f49
              version=v1
Annotations:  <none>
Status:       Running
IP:           10.244.1.2
...

We see here that both 'app' and 'version' labels are attached now to our Pod
(as well as another label generated by Kubernetes for its own usage). And we
can query now the list of pods using the new label:

tuto@laptop:~$ kubectl get pods -l version=v1
NAME                     READY   STATUS    RESTARTS   AGE
hello-5bfc654f49-bvbw5   1/1     Running   0          13m

And we see the Pod.


5.5 - Deleting a service
========================

To delete Services you can use the delete service command. Labels can be used
also here:

tuto@laptop:~$ kubectl delete service -l app=hello
service "hello" deleted

Confirm that the service is gone:

tuto@laptop:~$ kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   18m

This confirms that our Service was removed. To confirm that route is not
exposed anymore you can curl the previously exposed IP and port:

tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
curl: (7) Failed to connect to 172.17.0.3 port 31100: Connection refused


This proves that the app is not reachable anymore from outside of the cluster,
but it does NOT imply that the Pods are down: by putting don the 'Service', we
only impacted the way the cluster is exposing these Pods to the outside world.
But not how they run WITHIN the cluster.

You can confirm that the app is still running with a curl inside the pod:

tuto@laptop:~$ kubectl exec -ti $POD_NAME curl localhost:80
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-bvbw5<br/>
tuto@laptop:~$

We see here that the application is up. This is because the Deployment is
managing the application. To shut down the application, you would need to
delete the Deployment as well.

So let'now restart the service so that we can finish this part of the tutorial:

tuto@laptop:~$ kubectl expose deployment/hello --type="NodePort" --port 80
service/hello exposed

And we need to refresh the NodePort value and test that the app is still
reachable from within the cluster:

tuto@laptop:~$ kubectl describe svc/hello
Name:                     hello
Namespace:                default
Labels:                   app=hello
Annotations:              <none>
Selector:                 app=hello
Type:                     NodePort
IP:                       10.105.161.103
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31769/TCP
Endpoints:                10.244.1.2:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

The NodePort was renewed, and we must refresh our variable:

tuto@laptop:~$ NODE_PORT=31769
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-bvbw5<br/>

We're ready for the next section :-)


6 - Scale Your App
==================


6.1 - Explanation - Scaling an application
==========================================

In the previous modules we created a Deployment, and then exposed it publicly
via a Service. The Deployment created only one Pod for running our
application. When traffic increases, we will need to scale the application to
keep up with user demand.

Scaling is accomplished by changing the number of replicas in a Deployment.

(image - "scale your app - 1")
(image - "scale your app - 2")

Scaling out a Deployment will ensure new Pods are created and scheduled to
Nodes with available resources. Scaling will increase the number of Pods to
the new desired state. Kubernetes also supports autoscaling of Pods, but we
will not see it here in detail. Scaling to zero is also possible, and it will
terminate all Pods of the specified Deployment.

Running multiple instances of an application will require a way to distribute
the traffic to all of them. 'Services' have an integrated load-balancer that
will distribute network traffic to all Pods of an exposed Deployment.
'Services' will monitor continuously the running Pods using endpoints, to
ensure the traffic is sent only to available Pods.


Once you have multiple instances of an Application running, you would be able
to do Rolling updates without downtime. We'll cover that in the next module.
Now, let's go to the online terminal and scale our application.


6.2 - Scaling a deployment
===========================

To list your deployments use the get deployments command:

tuto@laptop:~$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   1/1     1            1           19m

This shows:
    - READY shows the ratio of CURRENT to DESIRED replicas
        * CURRENT is the number of replicas running now
        * DESIRED is the configured number of replicas
    - UP-TO-DATE is the number of replicas that were updated to match the
        desired (configured) state
    - AVAILABLE state shows how many replicas are actually AVAILABLE to the
        users

Next, let’s scale the Deployment to 4 replicas. We’ll use the kubectl scale
command, followed by the deployment type, name and desired number of
instances:

tuto@laptop:~$ kubectl scale deployments/hello --replicas=4
deployment.apps/hello scaled

To list your Deployments once again, use get deployments:

tuto@laptop:~$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   2/4     4            2           41m
tuto@laptop:~$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   4/4     4            4           41m

The change was applied, and we end up with 4 instances of the application
available. Next, let’s check if the number of Pods changed:

tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS              RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running             0          20m   10.244.1.2   newyear-worker    <none>           <none>
hello-5bfc654f49-hbpjq   0/1     ContainerCreating   0          1s    <none>       newyear-worker    <none>           <none>
hello-5bfc654f49-smdmq   0/1     ContainerCreating   0          1s    <none>       newyear-worker2   <none>           <none>
hello-5bfc654f49-v8k5q   0/1     ContainerCreating   0          1s    <none>       newyear-worker2   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS              RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running             0          20m   10.244.1.2   newyear-worker    <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Running             0          2s    10.244.1.3   newyear-worker    <none>           <none>
hello-5bfc654f49-smdmq   0/1     ContainerCreating   0          2s    <none>       newyear-worker2   <none>           <none>
hello-5bfc654f49-v8k5q   0/1     ContainerCreating   0          2s    <none>       newyear-worker2   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running   0          21m   10.244.1.2   newyear-worker    <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Running   0          25s   10.244.1.3   newyear-worker    <none>           <none>
hello-5bfc654f49-smdmq   1/1     Running   0          25s   10.244.2.6   newyear-worker2   <none>           <none>
hello-5bfc654f49-v8k5q   1/1     Running   0          25s   10.244.2.7   newyear-worker2   <none>           <none>

There are 4 Pods now, with different IP addresses. The change was registered
in the Deployment events log. To check that, use the describe command:

tuto@laptop:~$ kubectl describe deployments/hello
Name:                   hello
Namespace:              default
CreationTimestamp:      Wed, 01 Jan 2020 16:21:15 +0100
Labels:                 app=hello
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=hello
Replicas:               4 desired | 4 updated | 4 total | 4 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=hello
  Containers:
   learn-kubernetes:
    Image:        tsouche/learn-kubernetes:part3
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   hello-5bfc654f49 (4/4 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  21m   deployment-controller  Scaled up replica set hello-5bfc654f49 to 1
  Normal  ScalingReplicaSet  84s   deployment-controller  Scaled up replica set hello-5bfc654f49 to 4


You can also view in the output of this command that there are 4 replicas now.
Interestingly, you can also see at the bottom a full history of the Deployment,
showing how it was set initially at 1 instance, and then scaled up to 4.


6.3 - Load Balancing
====================

Let’s check that the Service is load-balancing the traffic. To find out the
exposed IP and Port we can use the 'describe service' as we learned in the
previous section:

tuto@laptop:~$ kubectl describe services/hello
Name:                     hello
Namespace:                default
Labels:                   app=hello
Annotations:              <none>
Selector:                 app=hello
Type:                     NodePort
IP:                       10.105.161.103
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31769/TCP
Endpoints:                10.244.1.2:80,10.244.1.3:80,10.244.2.6:80 + 1 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

The ENDPOINT (the one used for the whole cluster, including the kubernetes
Service) did not change, so we can now do a curl to the exposed IP and port.
Execute the command multiple times:

tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-v8k5q<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-smdmq<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-v8k5q<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-bvbw5<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-bvbw5<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World!</h3><b>Hostname:</b> hello-5bfc654f49-hbpjq<br/>

We hit a different Pod with every request. This demonstrates that the
load-balancing is working.


6.4 - Scale Down
================

To scale down the Service to 2 replicas, run again the scale command:

tuto@laptop:~$ kubectl scale deployments/hello --replicas=2
deployment.apps/hello scaled

List the Deployments to check if the change was applied with the get
deployments command:

tuto@laptop:~$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   2/2     2            2           29m

The number of replicas decreased to 2. List the number of Pods:

tuto@laptop:~$ kubectl get pods -o wide
thierry@Ubuntu-thierry:~$ kubectl get pods -o wide
NAME                     READY   STATUS        RESTARTS   AGE     IP           NODE              NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running       0          26m     10.244.1.2   newyear-worker    <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Running       0          5m45s   10.244.1.3   newyear-worker    <none>           <none>
hello-5bfc654f49-smdmq   1/1     Terminating   0          5m45s   10.244.2.6   newyear-worker2   <none>           <none>
hello-5bfc654f49-v8k5q   1/1     Terminating   0          5m45s   10.244.2.7   newyear-worker2   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
thierry@Ubuntu-thierry:~$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE     IP           NODE             NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running   0          26m     10.244.1.2   newyear-worker   <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Running   0          6m18s   10.244.1.3   newyear-worker   <none>           <none>


This confirms that 2 Pods were terminated. You may see that the two remaining
Pods are both running on the slave 1, which may not be optimal: this can
actually be managed more tightly by setting affinity/anti-affinity rules on
the Deployment, but we will not get into this level of details here.



## 7 - Update Your App

### 7.1 - Updating an application

Users expect applications to be available all the time and developers are expected to deploy new versions of them several times a day. In Kubernetes this is done with rolling updates. Rolling updates allow Deployments' update to take place with zero downtime by incrementally updating Pods instances with new ones. The new Pods will be scheduled on Nodes with available resources.

In the previous module, we scaled our application to run multiple instances. This is a requirement for performing updates without affecting application availability. By default, the maximum number of Pods that can be unavailable during the update and the maximum number of new Pods that can be created, is one. Both options can be configured to either numbers or percentages (of Pods). In Kubernetes, updates are versioned and any Deployment update can be reverted to previous (stable) version.


### 7.2 - Rolling updates overview

(image: "update your app - 1")
(image: "update your app - 2")
(image: "update your app - 3")
(image: "update your app - 4")

Similar to application Scaling, if a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update. An available Pod is an instance that is available to the users of the application.

Rolling updates allow the following actions:
* Promote an application from one environment to another (via container image updates)
* Rollback to previous versions
* Continuous Integration and Continuous Delivery of applications with zero downtime


### 7.3 - Update the version of the app

To list your deployments use the get deployments command:
```
tuto@laptop:~$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   2/2     2            2           31m
```
To list the running Pods use the get pods command:
```
tuto@laptop:~$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
hello-5bfc654f49-bvbw5   1/1     Running   0          31m
hello-5bfc654f49-hbpjq   1/1     Running   0          10m
```
To view the current image version of the app, run a `describe` command against the Pods (look at the Image field):
```
tuto@laptop:~$ kubectl describe pods
Name:         hello-5bfc654f49-bvbw5
Namespace:    default
Priority:     0
Node:         newyear-worker/172.17.0.2
Start Time:   Wed, 01 Jan 2020 16:21:15 +0100
Labels:       app=hello
              pod-template-hash=5bfc654f49
              version=v1
Annotations:  <none>
Status:       Running
IP:           10.244.1.2
IPs:
  IP:           10.244.1.2
Controlled By:  ReplicaSet/hello-5bfc654f49
Containers:
  learn-kubernetes:
    Container ID:   containerd://1efd70fa3f226739dd4a4f264327496eb2195a6c1399d6d2bcd1ce08143d1d48
    Image:          tsouche/learn-kubernetes:part3
    Image ID:       docker.io/tsouche/learn-kubernetes@sha256:ba5e8b3f6868f7e3753d53227a1ec7032f1c9fb5749b54d147ae3729f11f170c
[...]
Events:
  Type    Reason     Age   From                     Message
  ----    ------     ----  ----                     -------
  Normal  Scheduled  31m   default-scheduler        Successfully assigned default/hello-5bfc654f49-bvbw5 to newyear-worker
  Normal  Pulling    31m   kubelet, newyear-worker  Pulling image "tsouche/learn-kubernetes:part3"
  Normal  Pulled     31m   kubelet, newyear-worker  Successfully pulled image "tsouche/learn-kubernetes:part3"
  Normal  Created    31m   kubelet, newyear-worker  Created container learn-kubernetes
  Normal  Started    31m   kubelet, newyear-worker  Started container learn-kubernetes


Name:         hello-5bfc654f49-hbpjq
Namespace:    default
Priority:     0
Node:         newyear-worker/172.17.0.2
Start Time:   Wed, 01 Jan 2020 16:41:50 +0100
Labels:       app=hello
              pod-template-hash=5bfc654f49
Annotations:  <none>
Status:       Running
IP:           10.244.1.3
IPs:
  IP:           10.244.1.3
Controlled By:  ReplicaSet/hello-5bfc654f49
Containers:
  learn-kubernetes:
    Container ID:   containerd://c73bec287600c26e3566c9455197fcfe9dc3e09455c7286ba11518085d95d823
    Image:          tsouche/learn-kubernetes:part3
    Image ID:       docker.io/tsouche/learn-kubernetes@sha256:ba5e8b3f6868f7e3753d53227a1ec7032f1c9fb5749b54d147ae3729f11f170c
[...]
Events:
  Type    Reason     Age   From                     Message
  ----    ------     ----  ----                     -------
  Normal  Scheduled  11m   default-scheduler        Successfully assigned default/hello-5bfc654f49-hbpjq to newyear-worker
  Normal  Pulled     11m   kubelet, newyear-worker  Container image "tsouche/learn-kubernetes:part3" already present on machine
  Normal  Created    11m   kubelet, newyear-worker  Created container learn-kubernetes
  Normal  Started    11m   kubelet, newyear-worker  Started container learn-kubernetes
```

To update the image of the application to version 2, use the `set image` command, followed by the deployment name and the new image version:
```
tuto@laptop:~$ kubectl set image deployment/hello learn-kubernetes=tsouche/learn-kubernetes:part3v2
deployment.apps/hello image updated
```

The command notified the Deployment to use a different image for your app and initiated a rolling update. Check the status of the new Pods, and view the old one terminating with the `get pods` command:
```
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS              RESTARTS   AGE   IP           NODE             NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running             0          65m   10.244.1.2   newyear-worker   <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Running             0          44m   10.244.1.3   newyear-worker   <none>           <none>
hello-85b6f6f55c-25vtd   0/1     ContainerCreating   0          2s    <none>       newyear-worker   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE             NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running   0          65m   10.244.1.2   newyear-worker   <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Running   0          44m   10.244.1.3   newyear-worker   <none>           <none>
hello-85b6f6f55c-25vtd   1/1     Running   0          21s   10.244.1.6   newyear-worker   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS              RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Running             0          65m   10.244.1.2   newyear-worker    <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Terminating         0          45m   10.244.1.3   newyear-worker    <none>           <none>
hello-85b6f6f55c-25vtd   1/1     Running             0          25s   10.244.1.6   newyear-worker    <none>           <none>
hello-85b6f6f55c-ts57p   0/1     ContainerCreating   0          4s    <none>       newyear-worker2   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS        RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Terminating   0          65m   10.244.1.2   newyear-worker    <none>           <none>
hello-5bfc654f49-hbpjq   1/1     Terminating   0          45m   10.244.1.3   newyear-worker    <none>           <none>
hello-85b6f6f55c-25vtd   1/1     Running       0          45s   10.244.1.6   newyear-worker    <none>           <none>
hello-85b6f6f55c-ts57p   1/1     Running       0          24s   10.244.2.8   newyear-worker2   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS        RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-5bfc654f49-bvbw5   1/1     Terminating   0          66m   10.244.1.2   newyear-worker    <none>           <none>
hello-85b6f6f55c-25vtd   1/1     Running       0          55s   10.244.1.6   newyear-worker    <none>           <none>
hello-85b6f6f55c-ts57p   1/1     Running       0          34s   10.244.2.8   newyear-worker2   <none>           <none>
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-85b6f6f55c-25vtd   1/1     Running   0          94s   10.244.1.6   newyear-worker    <none>           <none>
hello-85b6f6f55c-ts57p   1/1     Running   0          73s   10.244.2.8   newyear-worker2   <none>           <none>
```
Following the progress of the update, you see new Pods being created, and as the update progresses, old Pods being terminated, while the Deployment Controller always keeps (at least) the desired number of Pods active.

Since during a certain transition period both versions are active at the same time, the end users would not all get exactly the same experience: some will still hit the `v1` version, while other will already hit the `v2` version. However, this transition period may be kept reasonably short... if everything happens nominal.

Also, note that the two `v1` Pods were running on the same slave ('newyear-worker') while the two `v2` Pods are balanced across the two slaves.


### 7.4 - Verify an update

First, let’s check that the App is running. To find out the exposed IP and Port we can use describe service:
```
tuto@laptop:~$ kubectl describe services/hello
```
The `NodePort` did not change (since the update took place within the service which kept up), and neither did the `EntryPoint` for the whole cluster, so we can still poll the service at the same URL:
```
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World! - this is version 2</h3><b>Hostname:</b> hello-85b6f6f55c-25vtd<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World! - this is version 2</h3><b>Hostname:</b> hello-85b6f6f55c-ts57p<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World! - this is version 2</h3><b>Hostname:</b> hello-85b6f6f55c-25vtd<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World! - this is version 2</h3><b>Hostname:</b> hello-85b6f6f55c-25vtd<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World! - this is version 2</h3><b>Hostname:</b> hello-85b6f6f55c-ts57p<br/>
tuto@laptop:~$ curl $ENDPOINT:$NODE_PORT
<h3>Hello World! - this is version 2</h3><b>Hostname:</b> hello-85b6f6f55c-ts57p<br/>
```
So we can observe that:
* we hit a different Pod with every request, and
* all Pods are running the latest version (v2).

The update can be confirmed also by running a rollout status command:
```
tuto@laptop:~$ kubectl rollout status deployments/hello
deployment "hello" successfully rolled out
```
To view the current image version of the app, run a describe command against
the Pods:
```
tuto@laptop:~$ kubectl describe deployment/hello
Name:                   hello
Namespace:              default
CreationTimestamp:      Sat, 04 Jan 2020 20:42:27 +0100
Labels:                 app=hello
Annotations:            deployment.kubernetes.io/revision: 2
Selector:               app=hello
Replicas:               6 desired | 6 updated | 6 total | 6 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=hello
  Containers:
   learn-kubernetes:
    Image:        tsouche/learn-kubernetes:part3v2
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
[...]
```
We run now the version 2 of the app!


### 7.5 - Rollback an update

Let’s perform another update, and deploy image tagged as v10 :
```
tuto@laptop:~$ kubectl set image deployment/hello learn-kubernetes=tsouche/learn-kubernetes:part3v10
deployment.apps/hello image updated
```
Use get deployments to see the status of the deployment:
```
tuto@laptop:~$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   2/2     1            2           81m
```
And something is wrong… We do not have the desired number of Pods available. List the Pods again:
```
tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS             RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-68f977cb64-5fbcj   0/1     ImagePullBackOff   0          27s   10.244.1.7   newyear-worker    <none>           <none>
hello-85b6f6f55c-25vtd   1/1     Running            0          17m   10.244.1.6   newyear-worker    <none>           <none>
hello-85b6f6f55c-ts57p   1/1     Running            0          16m   10.244.2.8   newyear-worker2   <none>           <none>
```
A describe command on the Pods should give more insights:
```
tuto@laptop:~$ kubectl describe pods
```
The output is, as usual, very verbose, so we isolate only the events associated to the first Pod:
```
Events:
  Type     Reason     Age                From                     Message
  ----     ------     ----               ----                     -------
  Normal   Scheduled  54s                default-scheduler        Successfully assigned default/hello-68f977cb64-5fbcj to newyear-worker
  Normal   BackOff    22s (x2 over 51s)  kubelet, newyear-worker  Back-off pulling image "tsouche/learn-kubernetes:part3v10"
  Warning  Failed     22s (x2 over 51s)  kubelet, newyear-worker  Error: ImagePullBackOff
  Normal   Pulling    7s (x3 over 53s)   kubelet, newyear-worker  Pulling image "tsouche/learn-kubernetes:part3v10"
  Warning  Failed     5s (x3 over 51s)   kubelet, newyear-worker  Failed to pull image "tsouche/learn-kubernetes:part3v10": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/tsouche/learn-kubernetes:part3v10": failed to resolve reference "docker.io/tsouche/learn-kubernetes:part3v10": docker.io/tsouche/learn-kubernetes:part3v10: not found
  Warning  Failed     5s (x3 over 51s)   kubelet, newyear-worker  Error: ErrImagePull
```

There is no image tagged `part3v10` in the repository, so Kubernetes is not able to pull the image. Let’s roll back to our previously working version. We’ll use the `rollout undo` command:
```
tuto@laptop:~$ kubectl rollout undo deployments/hello
deployment.apps/hello rolled back
```
The rollout command reverted the deployment to the previous known state (v2 of the image). Updates are versioned and you can revert to any previously know state of a Deployment. List again the Pods:
```
tuto@laptop:~$kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
hello   2/2     2            2           83m

tuto@laptop:~$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
hello-85b6f6f55c-25vtd   1/1     Running   0          18m   10.244.1.6   newyear-worker    <none>           <none>
hello-85b6f6f55c-ts57p   1/1     Running   0          18m   10.244.2.8   newyear-worker2   <none>           <none>
```
Two Pods are running. Check again the image deployed on the them:
```
tuto@laptop:~$ kubectl describe pods
```
We see that the deployment is using a stable version of the `app` (v2). The Rollback was successful.


## 8 - Conclusion

At this step in the tutorial, you know how to deploy a stateless app on the cluster, and how to manage simple operations like a scaling in and out, or a version update.

Let's make it clear however that this is greatly simplified by the high level of automation made possible through Kubernetes: you actually only managed 'labels', and every command we did though `kubectl` could have been done by managing `YAML` files (i.e. by updating `YAML` files and feeding these files to the Master) or by directly accessing the REST APIs like the dashboard does.

It is time now to get into slightly more complex things like a...
... stateful app: let's get to Part 4 of the tutorial.
