# Appendix 0 - Setting up the Kubernetes cluster


## 1 - Introduction

We will describe here the setting up of a Kubernetes cluster using `Kind`, i.e. simulating each Node with a Docker container, and faking teh behaviour of the Kubernetes cluster. `Kind` does it so well that the Pods have no clue that their containers are running directly on the host: they are actually being proxied by the *Containers-behaving-as-Nodes*: in this way, Kubelet sees the Master exactly the same way as if it were running on a *true* Node (i.e. a VM or on bare metal), and the API servers exposes exactly the same APIs as a genuie cluster (`Kind` is certified *K8s compliant* by the CNCF).

We provide two scripts which automate the full procedure of:

1. installing the libraries required for this tutorial (git, curl, docker, kind, kubectl) setting up the cluster
2. deploying the cluster and the dashboard.

These scripts are in the main directory: `install.sh` and `deploy.sh`. We will now describe the steps gathered in these two scripts, so that you can understand the procedure to setup a `Kind` cluster.

The procedure can also be followed on a VM, which make the tutorial more portable: We will describe later in this appendix the setup of such a VM, using Vagrant and VirtualBox: the resulting image can then run on a windows machine.

> Note: Kubernetes evolves constantly as the community keeps enriching/improving/patching it. As a consequence, I experienced  at least two version changes with `Kind`, with for instance the need to keep strictly aligned align the versions of the `dashboard` and of `Kubectl` with the one of `Kind`. And obviously, very little documentation is available to explains the dependencies: trial and error remains the rule...

## 2 - Prepare the machine

We assume again that you have a Linux laptop and an account with `sudo` privilege.

In order to avoid multiple side effects due to version changes, here is the set
of verions used for all main components:
    - docker of version 18.9 minimum
    - GO version 1.13 (language on which Kind is developped)
    - Kind version 0.6.1 (which runs Kubernetes version 1.16.0)
    - dashboard version 2.0.0 beta 8
    - kubectl version 1.16.4

The corresponding binary files are available in the 'deploy-cluster-kind'
directory.


Step 1: remove possible temporary files
=======================================

Previous deployments may have left temporary files, which may interfere with
the proper rollout of the cluster. The first step is to remove all of them:

$ rm -rf .kube
$ rm recommended.yaml
$ rm -rf data_dashboard_token
$ mkdir /.kube


Step 2: deploy the cluster
==========================

Kind automates the deployment of the cluster: we need to pass only two
arguments to kind:

    - the configuration of the cluster: the API's version, the number of nodes.
      The configuration file called 'kind-cluster.yaml' is located in the
      'deploy-cluster-kind' directory.
    - the name of the cluster: Kind can manage multiple clusters simultaneously
      and it can distinguish them only by their name.

The command is then:


$ kind create cluster --config kind-cluster.yaml --name newyear


Step 3: deploy the dashboard (web GUI)
======================================

The next step is to deploy the dashboard on top of the Kubernetes clsuter: the
dashboard actually runs on the cluster exactly the same way as any other
application. You need to use 'kubectl' and inject a YAML file in the cluster.

The YAML file is the one corresponding to the version 2.0.0 beta 8, available
in the 'deploy-cluster-kind' directory, and the command is:

$ kubectl apply -f dashboard-v200b8-recommended.yaml

We then create a 'sample user', i.e. a user with the profile and rights to
access the dashboard application:

$ kubectl apply -f dashboard-adminuser.yaml

Finally, we need to collect the secret token (which is needed to log on the
dashboard from within a browser): we use the 'get secret' command to identify
the user, and then the 'describe secret' to exctract the token:

$ admin_profile=$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
$ dashboard_token_full=$(kubectl -n kubernetes-dashboard describe secret $admin_profile | grep "token: ")

We remove various other element in the string, ni order to keep the token only:

$ dashboard_token=${dashboard_token_full#"token: "}

We save the token in a file called 'data_dashboard_token':

$ echo $dashboard_token > data_dashboard_token


Step 4: access the dashboard from a browser
===========================================

To access the dashboard from a browser, you will need to make the dashbaord
service accessible from otuside the cluster, with a proxy, and the token
collected at the end of Step 3.

The proxy will be established by Kubectl: open a different terminal window, and
run the following command from this new terminal:

$ kubectl proxy -p 8001
Starting to serve on 127.0.0.1:8001

Thanks to this proxy, you can now access the dashboard service from the laptop:
you simply have to copy the following URL in a browser:

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

You will see a login screen: choose the 'Token' option and paste the token in
the following field. Here you are!


Step 5: conclusion
==================

Thats's it: you have a cluster running, which you can access with Kubectl. It
simulates 3 nodes, and Kind spoofs Kubernetes: the various containers behave as
Nodes and Pods and interact via the API server, with kubelets. The fact that
the topology is now 100% logical (topology between containers) and not physical
(the containers do not run on different machines) is not visible from the
various Kubernetes components. The contianers respect the APIs.

The interest here is both simplicity and footprint:
    - simplicity snice it takes very few steps to get a full cluster up and
      running, without having to bother about the network and other
      miscellaneous details...
    - footprint because it takes just one 'kindest' container per node to
      simulate the whole underlying infrastructure, and you then get a
      light-weight Kubernetes.

To me, this is more than just a spoof: Kind could bring the steps towards a
'100% containers' Kubernetes, where the whole nifrastructure would ONLY manage
containers, and not anymore rotate around servers or VMs. To be continued...


                                    *

                                  *   *


===============================================================================

Part 3 - deployment on a medium-size VM with Kind cluster

===============================================================================


The 'combi' scenario came from the constraints of a colleague who could not run
the tutorial on a Linux laptop... because he does not have a computer running
Linux (he's a VP, not a developper: his laptop is running MS Office...).

I did not want to bother with proting the whole thing onto Windows, and I am
really not familiar with coding on windows: looking for a 'simple' way to meet
his need, I finally resolved into setting up a VM with all the prerequisites
(Ubuntu desktop, docker, GO, Kind, Kubectl...).

I initially went the Vagrant way: however, for some reason, I felt it difficult
to work out with a desktop linux, while everything works fine with server
versions). So I eventually decided to setup the VM with VirtualBox, export the
OVA VM image and make it available to students so that they can run the
tutorial 'as if they were running Kind on Linux'.

The VM was set:
    - from a Ubuntu 18.04.3 LTS base OS
    - with GO version 1.13
    - with Kind version 0.6.1
    - with Kubectl version 1.16.4

and I cloned the 'learn-kubernetes' tutorial into the /projects directory.

As of this step, it is then very similar with the Part 2:
    - deploy a cluster with Kind (config file and name)
    - deploy the dashboard and the sample user
    - copy the token and log into the dashboard from a browser


                                    *

                                  *   *


===============================================================================

Part 4 - automated deployment

===============================================================================


A shell script is available in the tutorial to launch automated deployment for
Part 1 and Part 2: the 'deploy-cluster.sh' will deploy either on VM or on
containers depending on the arguments passed:

$ ./deploy-cluster.sh arg

    arg = -v or --vm        it will deploy 3 VMs and a Kubernetes cluster on
                            the VMs.
    agr = -k or --kind      it will deploy a cluster on containers, using kind

The whole process is automated, and the scripts is quite explicit.
