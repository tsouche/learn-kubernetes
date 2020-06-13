# Part 5 - Deploy a Cassandra ring


This tutorial shows you how to develop a native cloud Cassandra deployment on Kubernetes. In this example, a custom Cassandra SeedProvider enables Cassandra to discover new Cassandra nodes as they join the cluster.

`StatefulSets` make it easier to deploy stateful applications within a clustered environment. For more information on the features used in this tutorial, see the StatefulSet documentation.


> TO BE DONE:
>
> * need to provide a storage class,
> * which will then enable setting up Persistent Volumes and Persistent Volume Claims,
> * which will then enable to setup a Stateful Set.

The purpose is to setup an alternative to the storage class defined at the end of the `cassandra-statefulset.yaml`:
```
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: fast
  provisioner: k8s.io/minikube-hostpath
  parameters:
    type: pd-ssd
```

## 5.1 - Cassandra on Docker

The Pods in this tutorial use the `gcr.io/google-samples/cassandra:v13` image from Google’s container registry. The Docker image above is based on debian-base and includes OpenJDK 8.

This image includes a standard Cassandra installation from the Apache Debian repo. By using environment variables you can change values that are inserted into the `cassandra.yaml` file.
```
    ENV VAR	DEFAULT VALUE
    CASSANDRA_CLUSTER_NAME	'Test Cluster'
    CASSANDRA_NUM_TOKENS	32
    CASSANDRA_RPC_ADDRESS	0.0.0.0
```

## 5.2 - Objectives

* Create and validate a Cassandra headless Service.
* Use a StatefulSet to create a Cassandra ring.
* Validate the StatefulSet.
* Modify the StatefulSet.
* deploy an app using the Cassandra ring to store data
* kill some Pods randomly to demonstrate that there is no pore SPOF (vs Part 4)
* Delete the StatefulSet and its Pods.


## 5.3 - Creating a Cassandra Headless Service

### 5.3.1 - Before you begin

To complete this tutorial, you should already have a basic familiarity with Pods, Services, and StatefulSets. In addition, you should:

* have deployed a Kubernetes cluster, and can manage it with `kubectl` command-line tool
* have stored locally the relevant YAML configuration files (`cassandra-service.yaml` and `cassandra-statefulset.yaml`)

> Caution: Cassandra is heavily pulling on the nodes resources, so we need to configure the underlying VMs accordingly:
* 4 CPUs
* 5GO (5120 MO) memory

### 5.3.2 - Create the Cassandra Service

A Kubernetes `Service` describes a set of Pods that perform the same task.

The following `Service` is used for DNS lookups between Cassandra Pods and
clients within the Kubernetes cluster.

File: `cassandra-service.yaml`
```
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

Apply this file (via `kubectl`) to create a `Service` to track all Cassandra StatefulSet:
```
$ kubectl apply -f cassandra-service.yaml
service/cassandra created
```

Check the status of the Cassandra Service:
```
$ kubectl get svc/cassandra
NAME        TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
cassandra   ClusterIP   None         <none>        9042/TCP   89s
```

The `Service` creation failed if anything else is returned.


### 5.3.3 - Using a StatefulSet to Create a Cassandra Ring

The StatefulSet manifest, included below, creates a Cassandra ring that consists of three Pods.

> Note: This example uses the default provisioner for Minikube. Please update the following `StatefulSet` for the cloud you are working with.

File: `cassandra-statefulset.yaml`

```
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
              initialDelaySeconds: 15
              timeoutSeconds: 5
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
          storageClassName: fast
          resources:
            requests:
              storage: 1Gi
    ---
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: fast
    provisioner: k8s.io/minikube-hostpath
    parameters:
      type: pd-ssd
```

Update the `StatefulSet` if necessary.

Create the *Cassandra StatefulSet* from the `cassandra-statefulset.yaml` file:
```
$ kubectl apply -f cassandra-statefulset.yaml
statefulset.apps/cassandra created
storageclass.storage.k8s.io/fast created
```

## 5.3.4 - Validating The Cassandra StatefulSet

Get details about the *Cassandra StatefulSet*:

```
$ kubectl get statefulset cassandra
NAME        READY   AGE
cassandra   0/3     36s
```

The StatefulSet resource deploys Pods sequentially. Get the Pods to see the ordered creation status:

```
$ kubectl get pods -l="app=cassandra"
NAME          READY     STATUS              RESTARTS   AGE
cassandra-0   1/1       Running             0          1m
cassandra-1   0/1       ContainerCreating   0          8s
```
It can take several minutes for all three Pods to deploy. Once they are deployed, the same command returns:

```
NAME          READY     STATUS    RESTARTS   AGE
cassandra-0   1/1       Running   0          10m
cassandra-1   1/1       Running   0          9m
cassandra-2   1/1       Running   0          8m
```

Run the *Cassandra nodetool* from within a Cassandra Pod to display the status of the ring.

```
$ kubectl exec -it cassandra-0 -- nodetool status
Datacenter: DC1-K8Demo
======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens       Owns (effective)  Host ID                               Rack
UN  172.17.0.5  83.57 KiB   32           74.0%             e2dd09e6-d9d3-477e-96c5-45094c08db0f  Rack1-K8Demo
UN  172.17.0.4  101.04 KiB  32           58.8%             f89d6835-3a42-4419-92b3-0e62cae1479c  Rack1-K8Demo
UN  172.17.0.6  84.74 KiB   32           67.1%             a6a1e8c2-3dc5-4417-b1a0-26507af2aaad  Rack1-K8Demo
```


## 5.3.5 - Modifying the Cassandra StatefulSet

Use `kubectl edit` to modify the size of a *Cassandra StatefulSet*.

Run the following command: `kubectl edit statefulset cassandra`. This command opens an editor in your terminal. The line you need to change is the replicas field. The following sample is an excerpt of the StatefulSet file:

```
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
    spec:
      replicas: 3
```

Change the number of replicas to 4, then save the manifest and apply the change. The *Cassandra StatefulSet* now contains 4 Pods. Get the *Cassandra StatefulSet* details to verify:

```
kubectl get statefulset cassandra
NAME        DESIRED   CURRENT   AGE
cassandra   4         4         36m
```

## 5.4 - Deploy an application using the Cassandra ring

### 5.4.1 - deploy and scale the back-end

### 5.4.2 - Deploy and scale the front-end

### 5.4.3 - Kill Pods and demonstrate resilience

### 5.4.4 - Kill nodes and demonstrate resilience


## 5.5 - Cleaning up

Deleting or scaling a StatefulSet down does not delete the volumes associated with the StatefulSet. This setting is for your safety because your data is more valuable than automatically purging all related StatefulSet resources.

> Warning: Depending on the storage class and reclaim policy, deleting the PersistentVolumeClaims may cause the associated volumes to also be deleted. Never assume you’ll be able to access data if its volume claims are deleted.

Run the following commands (chained together into a single command) to delete everything in the Cassandra StatefulSet:

```
grace=$(kubectl get po cassandra-0 -o=jsonpath='{.spec.terminationGracePeriodSeconds}') \
  && kubectl delete statefulset -l app=cassandra \
  && echo "Sleeping $grace" \
  && sleep $grace \
  && kubectl delete pvc -l app=cassandra

```

Run the following command to delete the Cassandra Service.

```
kubectl delete service -l app=cassandra
```

## 5.6 - Conclusion
