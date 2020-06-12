# Part 4 - Deploy a stateful app


In this section, you will build and deploy a simple, multi-tier web application - a PHP Guestbook application with Redis - using Kubernetes and Docker. This example consists of the following components:
* a single-instance Redis master to store guestbook entries
* multiple replicated Redis instances to serve reads
* multiple web frontend instances


## 4.1 - Start up the Redis Master

The guestbook application uses Redis to store its data. It writes its data to a Redis master instance and reads data from multiple Redis slave instances.

### 4.1.1 - Creating the Redis Master Deployment

The manifest file, included below, specifies a `Deployment` controller that runs a single replica Redis master Pod.

File: `app-guestbook/redis-master-deployment.yaml`
```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: redis-master
  labels:
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      containers:
      - name: master
        image: k8s.gcr.io/redis:e2e  # or just image: redis
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
```

Launch a terminal window in the directory where you downloaded the manifest files. Apply the *Redis Master Deployment* from the `redis-master-deployment.yaml` file:

```
tso@laptop:~$ cd /projects/lean-kubernetes/app-guestbook
tso@laptop:~$ kubectl apply -f redis-master-deployment.yaml
kubectl apply -f redis-master-deployment.yaml
```

Query the list of Pods to verify that the Redis Master Pod is running:

```
tso@laptop:~$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE    IP           NODE              NOMINATED NODE   READINESS GATES
redis-master-7db7f6579f-8dbh8   1/1     Running   0          39s    10.244.1.8   newyear-worker    <none>           <none>
```

Run the following command to view the logs from the Redis Master Pod:

```
$ POD_NAME=redis-master-7db7f6579f-8dbh8
$ kubectl logs -f $POD_NAME
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 2.8.19 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in stand alone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 1
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           http://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

[1] 01 Jan 19:29:47.717 # Server started, Redis version 2.8.19
[1] 01 Jan 19:29:47.717 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
[1] 01 Jan 19:29:47.717 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
[1] 01 Jan 19:29:47.717 * The server is now ready to accept connections on port 6379
```

Here we are: the Pods is running and the master DB server has started, it is listening on port 6379.


### 4.1.2 - Creating the *Redis Master Service*

The guestbook applications needs to communicate to the Redis master to write its data. You need to apply a `Service` to proxy the traffic to the Redis master Pod. A `Service` defines a policy to access the Pods.

The *Redis Master Service* is defined in the following `redis-master-service.yaml` file:

File: `app-guestbook/redis-master-service.yaml`
```
apiVersion: v1
kind: Service
metadata:
  name: redis-master
  labels:
    app: redis
    role: master
    tier: backend
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
    role: master
    tier: backend
```

Let's set up and run the *Redis Master Service*:

```
$ kubectl apply -f redis-master-service.yaml
service/redis-master created
```

Query the list of `Services` to verify that the *Redis Master Service* is running:
```
$ kubectl get service
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP        4h18m
redis-master   ClusterIP   10.105.70.232    <none>        6379/TCP       16s
```

This manifest file creates a `Service` named `redis-master` with a set of labels that match the labels previously defined on the `Deployment`, so the `Service` routes network traffic to the Redis master Pod.

You have here again an example of how important labels are with Kubernetes.


## 4.2 - Start up the Redis Slaves

Although the Redis master is a single pod, you can make it highly available to meet traffic demands by adding replica Redis slaves. This is not really a 'high availability' (HA) setup, since the Master node still is a Single Point Of Failure (SPOF) but it nevertheless brings resilience for the read operations, which is very important in many applicaitons (i.e. in many cases, the application read vey often and writes much more rarely).


### 4.2.1 - Creating the *Redis Slave Deployment*

`Deployments` scale based of the configurations set in the manifest file. In this case, the `Deployment` object specifies two replicas.

If there are not any replicas running, this `Deployment` would start the two replicas on your container cluster. Conversely, if there are more than two replicas are running, it would scale down until two replicas are running.

File: `app-guestbook/redis-slave-deployment.yaml`
```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: redis-slave
  labels:
    app: redis
  spec:
   selector:
     matchLabels:
       app: redis
       role: slave
       tier: backend
   replicas: 2
   template:
     metadata:
       labels:
         app: redis
         role: slave
         tier: backend
     spec:
       containers:
       - name: slave
         image: gcr.io/google_samples/gb-redisslave:v3
         resources:
           requests:
             cpu: 100m
             memory: 100Mi
         env:
         - name: GET_HOSTS_FROM
           value: dns
           # Using `GET_HOSTS_FROM=dns` requires your cluster to
           # provide a dns service. As of Kubernetes 1.3, DNS is a built-in
           # service launched automatically. However, if the cluster you are using
           # does not have a built-in DNS service, you can instead
           # access an environment variable to find the master
           # service's host. To do so, comment out the 'value: dns' line above, and
           # uncomment the line below:
           # value: env
         ports:
         - containerPort: 6379
```

Let's apply this file to run the *Redis Slave Deployment*:

```
$ kubectl apply -f redis-slave-deployment.yaml
deployment.apps/redis-slave created
```

Query the list of Pods to verify that the Redis Slave Pods are running:

```
$ kubectl get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE     IP           NODE              NOMINATED NODE   READINESS GATES
redis-master-7db7f6579f-8dbh8   1/1     Running   0          11m     10.244.1.8   newyear-worker    <none>           <none>
redis-slave-7664787fbc-ccjkt    1/1     Running   0          21s     10.244.2.9   newyear-worker2   <none>           <none>
redis-slave-7664787fbc-md4tr    1/1     Running   0          21s     10.244.1.9   newyear-worker    <none>           <none>
```


### 4.2.2 - Creating the Redis Slave Service

The guestbook application needs to communicate to Redis slaves to read data. To make the Redis slaves discoverable, you need to set up a `Service`. A `Service` provides transparent load balancing to a set of Pods.

File: `app-guestbook/redis-slave-service.yaml`


```
apiVersion: v1
kind: Service
metadata:
  name: redis-slave
  labels:
    app: redis
    role: slave
    tier: backend
spec:
  ports:
  - port: 6379
  selector:
    app: redis
    role: slave
    tier: backend
```

Let's apply this file to run the *Redis Slave Service*:

```
$ kubectl apply -f redis-slave-service.yaml
service/redis-slave created
```

Query the list of `Services` to verify that the *Redis slave Service* is running:

```
$ kubectl get services
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP        4h25m
redis-master   ClusterIP   10.105.70.232    <none>        6379/TCP       7m8s
redis-slave    ClusterIP   10.100.216.148   <none>        6379/TCP       16s
```

## 4.3 - Set up and Expose the Guestbook Frontend

The guestbook application has a web frontend serving the HTTP requests written in PHP. It is configured to connect to the redis-master `Service` for write requests and the redis-slave service for Read requests.


### 4.3.1 - Creating the Guestbook Frontend Deployment


File: `app-guestbook/frontend-deployment.yaml`

```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
Kind: Deployment
metadata:
  name: frontend
    labels:
      app: guestbook
spec:
  selector:
    matchLabels:
      app: guestbook
      tier: frontend
  replicas: 3
  template:
    metadata:
      labels:
        app: guestbook
        tier: frontend
    spec:
      containers:
      - name: php-redis
      resources:
        image: gcr.io/google-samples/gb-frontend:v4
          requests:
            cpu: 100m
            memory: 100Mi
        env:
       - name: GET_HOSTS_FROM
         value: dns
         # Using `GET_HOSTS_FROM=dns` requires your cluster to
         # provide a dns service. As of Kubernetes 1.3, DNS is a built-in
         # service launched automatically. However, if the cluster you are using
         # does not have a built-in DNS service, you can instead
         # access an environment variable to find the master
         # service's host. To do so, comment out the 'value: dns' line above, and
         # uncomment the line below:
         # value: env
       ports:
       - containerPort: 80
```

Let's apply this file to run the *frontend Deployment*:

```
$ kubectl apply -f frontend-deployment.yaml
deployment.apps/frontend created
```

Query the list of Pods to verify that the 3 frontend replicas are running:

```
$ kubectl get pods -l app=guestbook -l tier=frontend -o wide
NAME                        READY   STATUS    RESTARTS   AGE   IP            NODE              NOMINATED NODE   READINESS GATES
frontend-6cb7f8bd65-7glwf   1/1     Running   0          27s   10.244.1.10   newyear-worker    <none>           <none>
frontend-6cb7f8bd65-xm2sz   1/1     Running   0          27s   10.244.2.10   newyear-worker2   <none>           <none>
frontend-6cb7f8bd65-zv5qh   1/1     Running   0          27s   10.244.1.11   newyear-worker    <none>           <none>

$ kubectl get pods -l app=guestbook -l tier=backend -o wide
NAME                            READY   STATUS    RESTARTS   AGE     IP           NODE              NOMINATED NODE   READINESS GATES
redis-master-7db7f6579f-8dbh8   1/1     Running   0          14m     10.244.1.8   newyear-worker    <none>           <none>
redis-slave-7664787fbc-ccjkt    1/1     Running   0          4m18s   10.244.2.9   newyear-worker2   <none>           <none>
redis-slave-7664787fbc-md4tr    1/1     Running   0          4m18s   10.244.1.9   newyear-worker    <none>           <none>
```

You can see again the importance of well thingking through the use of `labels`: it can be overwelmingly powerful when the time comes to debug complex and seamingly erratic issues in production.


### 4.3.2 - Creating the Frontend Service

The redis-slave and *redis-master Services* you applied are only accessible within the container cluster because the default type for a `Service` is `ClusterIP`. `ClusterIP` provides a single IP address for the set of Pods the `Service` is pointing to. This IP address is accessible only within the cluster.

If you want guests to be able to access your guestbook, you must configure the *frontend Service* to be externally visible, so a client can request the `Service` from outside the container cluster. We will expose `Services` through `NodePort`.

> Note: Some cloud providers, like Google Compute Engine or Google Kubernetes Engine, support external load balancers. If your cloud provider supports load balancers and you want to use it, simply delete or comment out type: NodePort, and uncomment type: LoadBalancer.

File: `app-guestbook/frontend-service.yaml`

```
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # comment or delete the following line if you want to use a LoadBalancer
  type: NodePort
  # if your cluster supports it, uncomment the following to automatically create
  # an external load-balanced IP for the frontend service.
  # type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: guestbook
    tier: frontend
```

Let's apply this file to run the *frontend Service*:

```
$ kubectl apply -f frontend-service.yaml
service/frontend created
```

Query the list of `Services` to verify that the *frontend Service* is running:

```
$ kubectl get services
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
frontend       NodePort    10.98.51.214     <none>        80:31646/TCP   5m23s
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP        4h40m
redis-master   ClusterIP   10.105.70.232    <none>        6379/TCP       22m
redis-slave    ClusterIP   10.100.216.148   <none>        6379/TCP       15m
```

### 4.3.3 - Viewing the Frontend Service via NodePort

If you deployed this application to a local cluster, you need to find the IP address to view your Guestbook. As we did in the Part 3, we will use the `kubectl describe` command to collect the details on the `EndPoint` (the IP address which exposes all the `NodePorts` in the cluster) and the `NodePort` for the *frontend Service*:

```
$ kubectl describe svc/frontend
Name:                     frontend
Namespace:                default
Labels:                   app=guestbook
                          tier=frontend
Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                            {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"app":"guestbook","tier":"frontend"},"name":"frontend","namespa...
Selector:                 app=guestbook,tier=frontend
Type:                     NodePort
IP:                       10.98.51.214
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31646/TCP
Endpoints:                10.244.1.10:80,10.244.1.11:80,10.244.2.10:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason  Age   From                Message
  ----    ------  ----  ----                -------
  Normal  Type    5s    service-controller  LoadBalancer -> NodePort
```

You now know the `NodePort`: `31646`. Checking the kubernetes Service, you will also get the `EndPoint` which is used to expose all NodePort-type services:
```
$ kubectl describe svc/kubernetes
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
```

Here you are: `172.17.0.3`. You know both the IP and the port used to expose the frontend Service:
```
$ export ENDPOINT=172.17.0.3
$ export NODE_PORT=31646

$ curl $ENDPOINT:$NODE_PORT
curl $ENDPOINT:$NODE_PORT
<html ng-app="redis">
  <head>
    <title>Guestbook</title>
    <link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.2.12/angular.min.js"></script>
    <script src="controllers.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/angular-ui-bootstrap/0.13.0/ui-bootstrap-tpls.js"></script>
  </head>
  <body ng-controller="RedisCtrl">
    <div style="width: 50%; margin-left: 20px">
      <h2>Guestbook</h2>
    <form>
    <fieldset>
    <input ng-model="msg" placeholder="Messages" class="form-control" type="text" name="input"><br>
    <button type="button" class="btn btn-primary" ng-click="controller.onRedis()">Submit</button>
    </fieldset>
    </form>
    <div>
      <div ng-repeat="msg in messages track by $index">
        {{msg}}
      </div>
    </div>
    </div>
  </body>
</html>
```

We receive HTML code, which means that the server is well exposed at this URL. Copy this URL (`172.17.0.3:31646`) and load the page in your browser to view your guestbook: a very simple app enabling guests to exchange messages.


### 4.3.3 - Viewing the Frontend Service via LoadBalancer

If you deployed the `frontend-service.yaml` manifest with type: LoadBalancer you need to find the IP address to view your Guestbook. Run the following command to get the IP address for the frontend Service.
```
$ kubectl get service frontend
NAME       TYPE        CLUSTER-IP      EXTERNAL-IP        PORT(S)        AGE
frontend   ClusterIP   10.51.242.136   109.197.92.229     80:32372/TCP   1m
```
Copy the external IP address, and load the page in your browser to view your guestbook.


## 4.4 - Scale the Web Frontend

Scaling up or down is easy because your servers are defined as a `Service` that uses a Deployment controller.

Run the following command to scale up the number of frontend Pods:

```
$ kubectl scale deployment frontend --replicas=5
deployment.apps/frontend scaled
```

Query the list of Pods to verify the number of frontend Pods running:

```
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
frontend-6cb7f8bd65-4dst7       1/1     Running   0          8s
frontend-6cb7f8bd65-7glwf       1/1     Running   0          20m
frontend-6cb7f8bd65-fknr9       1/1     Running   0          8s
frontend-6cb7f8bd65-xm2sz       1/1     Running   0          20m
frontend-6cb7f8bd65-zv5qh       1/1     Running   0          20m
redis-master-7db7f6579f-8dbh8   1/1     Running   0          35m
redis-slave-7664787fbc-ccjkt    1/1     Running   0          24m
redis-slave-7664787fbc-md4tr    1/1     Running   0          24m
```

Run the following command to scale down the number of frontend Pods:

```
$ kubectl scale deployment frontend --replicas=2
deployment.apps/frontend scaled
```

Query the list of Pods to verify the number of frontend Pods running:

```
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
frontend-6cb7f8bd65-7glwf       1/1     Running   0          21m
frontend-6cb7f8bd65-xm2sz       1/1     Running   0          21m
redis-master-7db7f6579f-8dbh8   1/1     Running   0          36m
redis-slave-7664787fbc-ccjkt    1/1     Running   0          25m
redis-slave-7664787fbc-md4tr    1/1     Running   0          25m
```


## 4.5 - Cleaning up

Deleting the `Deployments` and `Services` also deletes any running Pods. Use `labels` to delete multiple resources with one command.

Run the following commands to delete all Pods, `Deployments`, and `Services`:

```
$ kubectl delete deployment -l app=redis
deployment.apps "redis-master" deleted
deployment.apps "redis-slave" deleted

$ kubectl delete service -l app=redis
service "redis-master" deleted
service "redis-slave" deleted

$ kubectl delete deployment -l app=guestbook
deployment.apps "frontend" deleted

$ kubectl delete service -l app=guestbook
service "frontend" deleted
```

Query the list of Pods to verify that no Pods are running:
```
$ kubectl get pods
No resources found in default namespace.
```

## 4.6 - Conclusion

I am not completely satisfied with this example: obviously, it show how easy it is to handle an application on top of Kubernetes, but it does not drill into the challenges of implementing statefulness on Kubernetes. To be improved and continued...
