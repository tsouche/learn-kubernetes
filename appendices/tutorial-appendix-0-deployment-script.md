# Appendix 0 - deploy a `Kind` cluster


## 1 - deploy the cluster

`KinD` stands for `Kubernetes - in - Docker`: it does not really deploy a Kubernetes cluster on your machine (i.e. it does not deplo Kubernetes on bare metal or on a virtual machine), but it instantiate a Docker container for each *Node* of the cluster, and then all the Kubernetes machinery runs wihtin these *Node containers*: the Master (including the scheduler, the API server, the various Controllers, the DNS and the Network controller, etc etc) and the workers (including Kubelet, local Docker runtime engine, and the Pods...). All these components behave like Docker containers running inside the *Node containers*, and they ignore that they are themselves *containers within containers*. Namely, the Kubernetes binaries are directly reused within `KinD` and instanciated in this very specific setup. Fore more details, see [here](https://kind.sigs.k8s.io/docs/user/quick-start/ "KinD Quick Start landing page").

One can say that `KinD` *fakes* a cluster: it is ideal for educational purposes, and it enables to have a cluster running on relatively low spec machines. It also bring a lot of functional testing capabilities prior to shipping an application in production on a *real* cluster.

Interestingly, `KinD`automates the deployment of the cluster and we need to pass very few arguments to get a cluster up and running :

* the configuration of the cluster: the API's version and the number of nodes. The configuration file called `kind-cluster-v2.yaml` is located in the `./cluster-deploy` directory.
* the annotation indicating that we will use an [Ambassador Ingress controller](https://kind.sigs.k8s.io/docs/user/ingress/ "KinD configuration for an Ambassador Ingress Controller")
* the name of the cluster: Kind can manage multiple clusters simultaneously and it can distinguish them only by their name.

With the `./deploy.sh` script, we copy and rename the required configuration files from `./cluster-deploy` to `./sandbox` (so that we can run several times a given step of the tutorial, with always the ability to reset the cluster and start from a fresh state), and then we use these files to follow three steps steps:

```bash
tuto@laptop:~/learn-kubernetes$ cp ./cluster-deploy/kind-cluster-v2.yaml \
                                   ./cluster-deploy/dashboard-v200-recommended.yaml \
                                   ./cluster-deploy/dashboard-adminuser.yaml \
                                   ./sandbox
```

### Step 1: deploy the cluster itself

```bash
tuto@laptop:~$ kind create cluster --config ./kind-cluster.yaml --name k8s-tuto
```

### Step 2: deploy the Ingress Controller

### Step 3 - deploy the dashboard (web GUI)

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

We save the token in a file called `dashboard_token`:

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

