# Part 2 - Setting up the Kubernetes cluster


## 2.1 - Introduction

We will describe here the setting up of a Kubernetes cluster using `Kind`, i.e. simulating each Node with a Docker container, and faking teh behaviour of the Kubernetes cluster. `Kind` does it so well that the Pods have no clue that their containers are running directly on the host: they are actually being proxied by the *Containers-behaving-as-Nodes*: in this way, Kubelet sees the Master exactly the same way as if it were running on a *true* Node (i.e. a VM or on bare metal), and the API servers exposes exactly the same APIs as a genuie cluster (`Kind` is certified *K8s compliant* by the CNCF).

We provide two scripts which automate the full procedure of:

1. installing the libraries required for this tutorial (git, curl, docker, kind, kubectl) setting up the cluster
2. deploying the cluster and the dashboard.

These scripts are in the main directory: `install.sh` and `deploy.sh`. We will now describe the steps gathered in these two scripts, so that you can understand the procedure to setup a `Kind` cluster.

The procedure can also be followed on a VM, which make the tutorial more portable: We will describe later in this appendix the setup of such a VM, using Vagrant and VirtualBox: the resulting image can then run on a windows machine.

> Note: Kubernetes evolves constantly as the community keeps enriching/improving/patching it. As a consequence, I experienced  at least two version changes with `Kind`, with for instance the need to keep strictly aligned align the versions of the `dashboard` and of `Kubectl` with the one of `Kind`. And obviously, very little documentation is available to explains the dependencies: trial and error remains the rule...

## 2.2 - Prepare the machine

We assume that you have a Linux laptop and an account with `sudo` privilege.

In order to make sure that all versions are compatible (it's moving fast) and we do not suffer side effects due to version changes, we force the versions for each component. Here are the verions used for this tutorial:

* `Docker` of version 18.9 minimum
* `GO` version 1.14.2 and later (language on which Kind is developped)
* `Kind` version 0.8.1 (which runs Kubernetes version 1.18.2)
* `dashboard` version 2.0.0
* `kubectl` version 1.18.2

The corresponding binary files are available in the `deploy` directory.

### 2.2.1 remove possible temporary files

Previous deployments may have left temporary files, which may interfere with the proper rollout of the cluster. The first step is to remove all of them:

```bash
tuto@laptop:~$ cd learn-kubernetes/
tuto@laptop:~/learn-kubernetes$ rm -rf .kube
tuto@laptop:~/learn-kubernetes$ mkdir ~/.kube
tuto@laptop:~/learn-kubernetes$ rm -rf sandbox
tuto@laptop:~/learn-kubernetes$ mkdir sandbox
```


### 2.2.2 - deploy the cluster

Kind automates the deployment of the cluster: we need to pass only two arguments to kind:

* the configuration of the cluster: the API's version and the number of nodes. The configuration file called `kind-cluster.yaml` is located in the `./deploy` directory.
* the name of the cluster: Kind can manage multiple clusters simultaneously and it can distinguish them only by their name.

We copy and rename the required original files from `./deploy` to `./sandbox` (so that we can run several times a given step of the tutorial, with always the ability to reset the cluster and start from a fresh state), and then we go in the `sandbox` directory for the following steps:

```bash
tuto@laptop:~/learn-kubernetes$ cp ./deploy/kind-cluster-v0.2.yaml ./sandbox/kind-cluster.yaml
tuto@laptop:~/learn-kubernetes$ cp ./deploy/dashboard-v200-recommended.yaml ./sandbox/recommended.yaml
tuto@laptop:~/learn-kubernetes$ cp ./deploy/dashboard-adminuser.yaml ./sandbox/dashboard-adminuser.yaml
tuto@laptop:~$ cd sandbox/
tuto@laptop:~/learn-kubernetes/sandbox$
```

From there, we have in the `./sandbox` directory all the files required to deploy the cluster:

```bash
tuto@laptop:~$ kind create cluster --config ./kind-cluster.yaml --name k8s-tuto
```

### 2.2.3 - deploy the dashboard (web GUI)

The next step is to deploy the dashboard on top of the Kubernetes clsuter: the dashboard actually runs on the cluster exactly the same way as any other application. You need to use `kubectl` and inject a YAML file in the cluster.

The YAML file is the one corresponding to the version 2.0.0, available in the `./deploy` directory, and the command is:

```bash
tuto@laptop:~/learn-kubernetes/sandbox$ kubectl apply -f recommended.yaml
```

We then create a *sample user*, i.e. a user with the correct profile and rights to access the dashboard application:

```bash
tuto@laptop:~/learn-kubernetes/sandbox$ kubectl apply -f dashboard-adminuser.yaml
```

Finally, we need to collect the secret token (which is needed to log on the dashboard from within a browser): we use the `kubectl get secret` command to identify the user, and then the `kubectl describe secret` command to extract the token:

```bash
tuto@laptop:~/learn-kubernetes/sandbox$ admin_profile=$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
tuto@laptop:~/learn-kubernetes/sandbox$ dashboard_token_full=$(kubectl -n kubernetes-dashboard describe secret $admin_profile | grep "token: ")
```
We remove various other element in the string, in order to keep the token only:

```bash
tuto@laptop:~/learn-kubernetes/sandbox$ dashboard_token=${dashboard_token_full#"token: "}
```

We save the token in a file called `data_dashboard_token`:

```bash
tuto@laptop:~/learn-kubernetes/sandbox$ echo $dashboard_token > data_dashboard_token
```

### 2.2.4 - access the dashboard from a browser

To access the dashboard from a browser, you will need to make the dashbaord service accessible from outside the cluster, with a proxy. This proxy will be established by `Kubectl`: open a second terminal window, and run the following command from this new terminal:

```bash
tuto@laptop:~/learn-kubernetes/sandbox$ kubectl proxy -p 8001
Starting to serve on 127.0.0.1:8001
```

Thanks to this proxy, you can now access the dashboard service from the laptop:
* come back to the previous terminal window, in order to be able to continue running commands towards the cluster (via `kubectl`) for the rest of the tutorial,
* and copy the following URL in a browser to access the dashboard:
  [http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)

* the browser (possibly you may need to refresh it after few seconds to give time to the cluster to start all services) will show a login page with two option: select the 'Token' box;
![alt txt](./images/tuto-2-dashboard-login-1.png "Dashboard login page")
* paste into the field the token (yeah, its a very long line);
![alt txt](./images/tuto-2-dashboard-login-2.png "Dashboard login page - fill the token")
* and you are logged into the dashboard, which is a web GUI to help you see what is happening in the cluster, and even to operate the cluster from there:
![alt txt](./images/tuto-2-dashboard-overview-1.png "Dashboard - overview of the cluster)")

You will see a login screen: choose the 'Token' option and paste the token in the following field. Here you are!


## 2.3 - Conclusion of the `kind` cluster deployment

Thats's it: you have a cluster running, which you can access with `kubectl`. It simulates 3 nodes, and `kind` spoofs Kubernetes: the various containers behave as Nodes and Pods and interact via the API server, with `kubelet`. The fact that the topology is now 100% logical (topology between containers) and not physical (the containers do not run on different machines) is not visible from the various Kubernetes components. The containers respect the APIs.

The interest here is both simplicity and footprint:
* simplicity snice it takes very few steps to get a full cluster up and running, without having to bother about the network and other miscellaneous details...
* footprint because it takes just one *kindest* container per node to simulate the whole underlying infrastructure, and you then get a light-weight Kubernetes.

To me, this is more than just a spoof: `Kind` could bring the steps towards a '100% containers' Kubernetes, where the whole infrastructure would ONLY manage containers, and not anymore rotate around servers or VMs. To be continued...



## 2.4 - Running the Kind cluster on a VM

This scenario comes from the constraints of a colleague who could not run the tutorial on a Linux laptop... because he does not have a computer running Linux (*he's a VP, not a developper: his laptop is running MS Office...*).

I did not want to bother with porting the whole thing onto Windows, and I am really not familiar with coding on windows: looking for a *simple* way to meet his need, I finally resolved into setting up a VM with all the prerequisites (Ubuntu desktop, docker, GO, Kind, Kubectl...).

I initially went the Vagrant way: however, for some reason, I felt it difficult to work out with a desktop linux, while everything works fine with server versions). So I eventually decided to setup the VM with VirtualBox, export the OVA VM image and make it available to students so that they can run the tutorial *as if they were running `kind` on Linux*.

The VM was set:
* from a Ubuntu 20.04 LTS base OS
* with `GO` version 1.14.2 or later
* with `kind` version 0.8.1
* with `kubectl` version 1.18.2

and I cloned the 'learn-kubernetes' tutorial into the `~/learn-kubernetes` directory.

As of this step, it is then very similar with the Part 2:
* deploy a cluster with `kind` (config file and name)
* deploy the `dashboard` and the sample user
* copy the token and log into the dashboard from a browser
