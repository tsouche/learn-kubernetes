# Part 5 - Deploy a Cassandra ring



## 5.1 - What about resilience on a Kubernetes Cluster

If you remember the Part 4, we deployed a Guestbook application which was composed of:

* a web frontend, replicated in multiple instances, and thus was resilient;
* a Redis backend, which relied on one Write Master, and multiple Slave Readers: while the read operations relied on multiple instances of the Redis Slave, posting an information on the datastore required to send the information to the unique Redis Master instance which was a SPOF.

And we demosntrated the problem by *killing* the Kubernetes _Node_ on which the Redis Master was running: the service went down.

In Part 5, we will show you how to enable a _truely resilient_ application on Kubernetes. To do so, we actually change the datastore technology: we replace Redis with Cassandra. But what is Cassandra?

* This is an open source distributed NoSQL database management system. It’s designed to handle large amounts of data across many different commodity servers, hence providing high availability with no single point of failure.
* It offers strong support for clusters that span various data centres, with its asynchronous masterless replication allowing low latency operations for all clients.

> Cassandra from ten thousand feet:
> The Apache Cassandra database is the right choice when you need scalability and high availability without compromising performance. Linear scalability and proven fault-tolerance on commodity hardware or cloud infrastructure make it the perfect platform for mission-critical data.
> Cassandra’s support for replicating across multiple datacenters is best-in-class, providing lower latency for your users and the peace of mind of knowing that you can survive regional outages.

Looking at Cassandra features, you may think that Father Christmas was coming to you before December:

* It supports replication and multiple data centre replication.
* It has immense scalability.
* It is fault-tolerant.
* It is decentralised.
* It has tunable consistency.
* It provides MapReduce support.
* It supports Cassandra Query Language (CQL) as an alternative to the Structured Query Language (SQL).

And obviously, such a performance comes with a price: deploying a production grade Cassadra ring is really complex, and requires expert tuning. Fortunately, as we have no ambition in this tutorial to get to such a level, we will use a very basic porting of Cassandra on Kubernetes. As a matter of fact, *we are NOT using a Rook operator setup* (which may be the topic of a future tutorial) and we rely on a basic 'Cassandra on Kubernetes' implementation. And this is enough to get acquainted with the basic concepts and taste of... **true resilience** :smile:.


The objectives of Part 5 are:

* to create and validate a Cassandra ring on Kuberntes (deploying a _Service_ and a _StatefulSet_);
* to deploy an app using the Cassandra ring to store data;
* to demonstrate that there is no pore SPOF;


## 5.2 - Deploying Cassandra on Kubernetes

Cassandra is handling persistent data, and thus we cannot use a basic _Deployment_ since it may generate side effects on:

* data consistency (the order in which we create/delete _Pods_ do matter), and
* data resilience (Cassandra will bind - unsing a PersistentVolumeClaims per Pod - to the StorageClass we choose, and the data should not be erased when the Cassandra Pod would crash and unbind from the storage).

As a consequence, Kubernetes offers the _StatefulSet_, which is dedicated to handling stateful applications. For more information on the features used in this tutorial, see the Storage Appendix.

> Caution: Cassandra is heavily pulling on the nodes resources, so we need to configure the underlying VMs accordingly:
> * 4 CPUs
> * 5GO (5120 MO) memory


### 5.2.1 - Create the Cassandra Service

A Kubernetes _Service_ describes a set of Pods that perform the same task. Here we will use a _Service_ in order to:

* enable all the _Pods_ belonging to the Cassandra ring to connect to each others and exchange data in order to maintain data eventual consistency between all the nodes of trhe ring;
* enable the clients to connect to the ring's Pods (DNS lookups).

File: `cassandra-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cassandra
  name: cassandra
spec:
  clusterIP: None
  ports:
  - port: 9042
  selector:
    app: cassandra
```

Apply this file (via `kubectl`) to create a _Service_ to track all _Cassandra StatefulSet_:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl apply -f app-cassandra/cassandra-service.yaml
service/cassandra created
```

Check the status of the _Cassandra Service_:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl get svc/cassandra
NAME        TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
cassandra   ClusterIP   None         <none>        9042/TCP   9s
```

The _Service_ creation failed if anything else is returned. At this moment, it is stil a "headless" service, since no _Pod_ was created to actually run the Cassandra cluster. To create these _Pods_, we will use a _StatefulSet_.


### 5.2.2 - Using a StatefulSet to Create a Cassandra Ring

The _StatefulSet_ manifest, included below, creates a Cassandra ring that consists of three _Pods_ (which is the minimum number of nodes required to get a Cassandra ring running).

File: `./app-cassandra/cassandra-statefulset.yaml`

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
  labels:
    app: cassandra
spec:
  serviceName: cassandra
  replicas: 3
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      terminationGracePeriodSeconds: 1800
      containers:
      - name: cassandra
        image: gcr.io/google-samples/cassandra:v13
        imagePullPolicy: Always
        ports:
        - containerPort: 7000
          name: intra-node
        - containerPort: 7001
          name: tls-intra-node
        - containerPort: 7199
          name: jmx
        - containerPort: 9042
          name: cql
        resources:
          limits:
            cpu: "500m"
            memory: 1Gi
          requests:
            cpu: "500m"
            memory: 1Gi
        securityContext:
          capabilities:
            add:
              - IPC_LOCK
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - nodetool drain
        env:
          - name: MAX_HEAP_SIZE
            value: 512M
          - name: HEAP_NEWSIZE
            value: 100M
          - name: CASSANDRA_SEEDS
            value: "cassandra-0.cassandra.default.svc.cluster.local"
          - name: CASSANDRA_CLUSTER_NAME
            value: "K8Demo"
          - name: CASSANDRA_DC
            value: "DC1-K8Demo"
          - name: CASSANDRA_RACK
            value: "Rack1-K8Demo"
          - name: POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
        readinessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - /ready-probe.sh
          # TSO: I changed the timeouts from respectively 15 and 5s to 25 and 15
          # seconds, in order to adapt to the speed of my laptop and to give a
          # chance to start properly the cassnadra cluster on a Kind cluster
          # running on my laptop.
          initialDelaySeconds: 25
          timeoutSeconds: 15
        # These volume mounts are persistent. They are like inline claims,
        # but not exactly because the names need to match exactly one of
        # the stateful pod volumes.
        volumeMounts:
        - name: cassandra-data
          mountPath: /cassandra_data
  # These are converted to volume claims by the controller
  # and mounted at the paths mentioned above.
  # do not use these in production until ssd GCEPersistentDisk or other ssd pd
  volumeClaimTemplates:
  - metadata:
      name: cassandra-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      # TSO: I changed the storageclass to 'standard' which is the local
      # storageclass implemented as 'default' on Kind (as of version 0.7).
      storageClassName: standard
      resources:
        requests:
          storage: 1Gi
```

Use the `kubectl apply` command to create the *Cassandra StatefulSet*:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl apply -f app-cassandra/cassandra-statefulset.yaml
statefulset.apps/cassandra created
```

## 5.2.3 - Validating The Cassandra StatefulSet

We now need to check that the *Cassandra StatefulSet* is actually running: the easiest way to do so is to identify and inspect (with `kubectl describe`) the _Pods_ on which the Cassandra ring runs:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl get statefulset cassandra
NAME        READY   AGE
cassandra   0/3     14s
```

The StatefulSet will deploy the 3 _Pods_ sequentially (and not in parallel as a stateless _Deployment_ may have done). Let's list the _Pods_ in order to see the ordered creation status:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl get pods -l="app=cassandra"  -o wide
NAME          READY   STATUS    RESTARTS   AGE   IP           NODE              NOMINATED NODE   READINESS GATES
cassandra-0   0/1     Running   0          24s   10.244.1.3   k8s-tuto-worker   <none>           <none>
tuto@laptop:~/learn-kubernetes$ kubectl get pods -l="app=cassandra"  -o wide
NAME          READY   STATUS              RESTARTS   AGE   IP           NODE               NOMINATED NODE   READINESS GATES
cassandra-0   1/1     Running             0          74s   10.244.1.3   k8s-tuto-worker    <none>           <none>
cassandra-1   0/1     ContainerCreating   0          4s    <none>       k8s-tuto-worker2   <none>           <none>
tuto@laptop:~/learn-kubernetes$ kubectl get pods -l="app=cassandra"  -o wide
NAME          READY   STATUS              RESTARTS   AGE    IP           NODE               NOMINATED NODE   READINESS GATES
cassandra-0   1/1     Running             0          3m4s   10.244.1.3   k8s-tuto-worker    <none>           <none>
cassandra-1   1/1     Running             0          114s   10.244.3.3   k8s-tuto-worker2   <none>           <none>
cassandra-2   0/1     ContainerCreating   0          3s     <none>       k8s-tuto-worker3   <none>           <none>
```

Cassandra is heavily pulling on the machine, so not everything always goes ok: looking at the second _Pod_, we see that there was an alert raised while the Pod was joining the Cassandra ring:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl describe pod/cassandra-1
Name:         cassandra-1
Namespace:    default
Priority:     0
Node:         k8s-tuto-worker2/172.18.0.2
Start Time:   Sat, 20 Jun 2020 21:42:26 +0200
Labels:       app=cassandra
[...]
Events:
  Type     Reason     Age                  From                       Message
  ----     ------     ----                 ----                       -------
  Normal   Scheduled  3m22s                default-scheduler          Successfully assigned default/cassandra-1 to k8s-tuto-worker2
  Normal   Pulling    3m21s                kubelet, k8s-tuto-worker2  Pulling image "gcr.io/google-samples/cassandra:v13"
  Normal   Pulled     3m11s                kubelet, k8s-tuto-worker2  Successfully pulled image "gcr.io/google-samples/cassandra:v13"
  Normal   Created    3m10s                kubelet, k8s-tuto-worker2  Created container cassandra
  Normal   Started    3m10s                kubelet, k8s-tuto-worker2  Started container cassandra
  Warning  Unhealthy  108s (x2 over 118s)  kubelet, k8s-tuto-worker2  Readiness probe failed:
```

As you can see at the bottom, the _Pod_ got a `Warning` with a status `Unhealthy`: this is because it was not answering the Master within a time limit. *Actually in order to get the ring running at all on my laptop, I had to increase (x3) the `timout` setting...*

It can take several minutes for all three Pods to deploy, but eventually, once they are deployed, the same command returns:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl get pods -l="app=cassandra"  -o wide
NAME          READY     STATUS    RESTARTS   AGE
NAME          READY   STATUS    RESTARTS   AGE     IP           NODE               NOMINATED NODE   READINESS GATES
cassandra-0   1/1     Running   0          7m42s   10.244.1.3   k8s-tuto-worker    <none>           <none>
cassandra-1   1/1     Running   0          6m32s   10.244.3.3   k8s-tuto-worker2   <none>           <none>
cassandra-2   1/1     Running   0          4m41s   10.244.2.7   k8s-tuto-worker3   <none>           <none>
```

We will now run the *Cassandra nodetool* from within a Cassandra Pod, and  display the status of the ring (as the ring's node see it). It takes some time for the the result to come:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl exec -it cassandra-0 -- nodetool status
Datacenter: DC1-K8Demo
======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens       Owns (effective)  Host ID                               Rack
UN  10.244.2.7   70.94 KiB  32           56.4%             0ff20718-1c4d-4fcf-bfdd-b242e61738aa  Rack1-K8Demo
UN  10.244.1.3  104.56 KiB  32           73.8%             2c4df617-f0fb-4c01-ad4f-91669be46503  Rack1-K8Demo
UN  10.244.3.3   84.82 KiB  32           69.9%             d3529f0b-19f9-44f2-9ac1-2b61ba6b26bd  Rack1-K8Demo

```


## 5.2.4 - Modifying the Cassandra StatefulSet (optional)

Use `kubectl edit` to modify the size of a *Cassandra StatefulSet*.

> `kubectl edit` will open the `vi` editor in your terminal so that you can edit various specifications of the object indicated with the `kubectl edit` command. The `vi` editor will show all the details of the object and let you modify them: you can see and edit all the details which you would have set in a YAML configuration file.
> Using `kubectle edit` is an interactive alternative to editing a YAML file and applying it using `kubectl apply -f`.

So you can now either run the `kubectl edit statefulset cassandra` command, or edit the `./app-cassandra/cassandra-statefulset.yaml` file. The following sample is an excerpt of the StatefulSet file opened in `vi`:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl edit statefulset cassandra
    # Please edit the object below. Lines beginning with a '#' will be ignored,
    # and an empty file will abort the edit. If an error occurs while saving this file will be
    # reopened with the relevant failures.
    #
    apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
    kind: StatefulSet
    metadata:
      creationTimestamp: 2016-08-13T18:40:58Z
      generation: 1
      labels:
      app: cassandra
      name: cassandra
      namespace: default
      resourceVersion: "323"
      uid: 7a219483-6185-11e6-a910-42010a8a0fc0
    [...]
    spec:
      replicas: 3
```

Change the number of replicas to 4, then save the manifest and apply the change. The *Cassandra StatefulSet* now contains 4 Pods.
> Again, alternatively, you can also edit the `app-cassandra/cassandra-statefulset.yaml` file and change the number of replicas from 3 to 4, and apply again the configuration file, using the command `kubectl apply -f ./app-cassandra/cassandra-statefulset.yaml`.

Get the *Cassandra StatefulSet* details to verify:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl get statefulset cassandra
NAME          READY   STATUS    RESTARTS   AGE     IP           NODE               NOMINATED NODE   READINESS GATES
cassandra-0   1/1     Running   0          10m     10.244.1.3   k8s-tuto-worker    <none>           <none>
cassandra-1   1/1     Running   0          9m43s   10.244.3.3   k8s-tuto-worker2   <none>           <none>
cassandra-2   1/1     Running   0          7m52s   10.244.2.7   k8s-tuto-worker3   <none>           <none>
cassandra-3   0/1     Running   0          5s      10.244.3.5   k8s-tuto-worker2   <none>           <none>
tuto@laptop:~/learn-kubernetes$ kubectl get pods -l="app=cassandra"  -o wide
NAME          READY   STATUS    RESTARTS   AGE     IP           NODE               NOMINATED NODE   READINESS GATES
cassandra-0   1/1     Running   0          19m     10.244.1.3   k8s-tuto-worker    <none>           <none>
cassandra-1   1/1     Running   0          18m     10.244.3.3   k8s-tuto-worker2   <none>           <none>
cassandra-2   1/1     Running   0          16m     10.244.2.7   k8s-tuto-worker3   <none>           <none>
cassandra-3   1/1     Running   0          8m40s   10.244.3.5   k8s-tuto-worker2   <none>           <none>
```

Having shown the possibility to scale out the ring, we will now scale it down since there is no use to have two ring's nodes on the same Kubernetes _Node_ *(you can see above that `cassandra-3` and is running on the same _Node_ as `cassandra-1`)*. To do so, we edit the YAML file, setting again the number of replicas to 3, and we apply it with the `kubectl apply -f ./app-cassandra/cassandra-statefulset.yaml` command.

The Kubernetes Master reacts immediately, and terminates the **last** _Pod_ created (since the Cassandra ring is managed as a _StatefulSet_, Pods are created/deleted in FILO order):

```bash
tuto@laptop:~/learn-kubernetes$ kubectl get pods -l="app=cassandra"  -o wide
NAME          READY   STATUS        RESTARTS   AGE   IP           NODE               NOMINATED NODE   READINESS GATES
cassandra-0   1/1     Running       0          22m   10.244.1.3   k8s-tuto-worker    <none>           <none>
cassandra-1   1/1     Running       0          20m   10.244.3.3   k8s-tuto-worker2   <none>           <none>
cassandra-2   1/1     Running       0          18m   10.244.2.7   k8s-tuto-worker3   <none>           <none>
cassandra-3   1/1     Terminating   0          11m   10.244.3.5   k8s-tuto-worker2   <none>           <none>
tuto@laptop:~/learn-kubernetes$ kubectl get pods -l="app=cassandra"  -o wide
NAME          READY   STATUS    RESTARTS   AGE   IP           NODE               NOMINATED NODE   READINESS GATES
cassandra-0   1/1     Running   0          23m   10.244.1.3   k8s-tuto-worker    <none>           <none>
cassandra-1   1/1     Running   0          22m   10.244.3.3   k8s-tuto-worker2   <none>           <none>
cassandra-2   1/1     Running   0          20m   10.244.2.7   k8s-tuto-worker3   <none>           <none>
```

As expected, the Cassandra ring is very soon set back to its initial dimension.


## 5.3 - Deploy an application using the Cassandra ring

### 5.3.1 - deploy and scale the front-end

### 5.3.2 - demonstrate distribution of execution

### 5.3.3 - kill _Pods_ and demonstrate resilience

### 5.3.4 - Kill _Nodes_ and demonstrate resilience


## 5.4 - Cleaning up

Deleting or scaling a _StatefulSet_ down does not delete the volumes associated with the _StatefulSet_. This setting is for your safety because your data is more valuable than automatically purging all related _StatefulSet_ resources.

> Warning: Depending on the _storage class_ and reclaim policy, deleting the `PersistentVolumeClaims` may cause the associated volumes to also be deleted. Never assume you’ll be able to access data if its volume claims are deleted.

In order to really delete all the _Cassandra StatefulSet_ resources, run the following commands:

```bash
tuto@laptop:~/learn-kubernetes$  kubectl get pvc
NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cassandra-data-cassandra-0   Bound    pvc-d9f317e8-8075-47fb-9111-a1d638885848   1Gi        RWO            standard       75m
cassandra-data-cassandra-1   Bound    pvc-a0f776e7-2e56-497c-b1b3-52ef426e444c   1Gi        RWO            standard       74m
cassandra-data-cassandra-2   Bound    pvc-b08a056e-3670-4f60-92dc-f8acf4da1047   1Gi        RWO            standard       72m
cassandra-data-cassandra-3   Bound    pvc-dc3900d2-b22b-4c44-9b90-f084232f7e57   1Gi        RWO            standard       65m

tuto@laptop:~/learn-kubernetes$ kubectl delete statefulset -l app=cassandra
statefulset.apps "cassandra" deleted

tuto@laptop:~/learn-kubernetes$ kubectl delete pvc -l app=cassandra
persistentvolumeclaim "cassandra-data-cassandra-0" deleted
persistentvolumeclaim "cassandra-data-cassandra-1" deleted
persistentvolumeclaim "cassandra-data-cassandra-2" deleted
persistentvolumeclaim "cassandra-data-cassandra-3" deleted
```

You can now delete the _Cassandra Service_, which is the only residual resource assigned to the Cassandra ring:

```bash
tuto@laptop:~/learn-kubernetes$ kubectl delete service -l app=cassandra
service "cassandra" deleted
```

## 5.6 - Conclusion

This time we have been able to demonstrate the actual interest of Kubernetes:

* we have very simply setup a very complex datastore, just using two configuration files and waiting few minutes;
* we have very simply deployed a stateful app which leveraged on the Cassandra datastore;
* we have demosntrated the resilience of the setup by killing Pods, Nodes and still showing that the service stayed up;

This is the last section of the tutorial: you have played with few concepts of Kubernetes, and you can now understand how powerfull K8s is. Obviously, this tutorial is only aiming at giving you this first insight on K8s, and setting up a 'production grade' Kubernetes service is far more complex.
