# Part 2 - Create a cluster

Let's now refine a bit few concepts on the node, and get these concepts in action in setting up and deploying a cluster!

The most interesting part of the tutorial is to manage applications on a  Kubernetes cluster, but it is actually also very interesting to take the time to learn how to set a cluster up. The methodology varies fast as the versions of `Kubernetes` keep evolving and there are now very automated ways to deploy a cluster on your local machine with minimalistic VMs (based on Container Linux). However, for the sake of simplicity and because I could not find the time to follow the pace with versions, and changes in the setup of a VM-based cluster, I am using here `KinD` (`Kubernetes in Docker`): it is ideal for simulating a cluster... and it is very easy.

`Kind` actually *fakes* a cluster by running each node (kubelet, proxy, etc tec) into a Docker container: this is less representative *(although one may think that the future of Kubernetes is possibly a very minimalistic OS running containers, and it may look more and more like Kind...)*, but it can run on a  much smaller footprint than spawining multiple VMs (which require a laptop with enough CPU and memeory to accomodate for 3 VM or more).

This may also be run in
* and finally we need a **'combo scenario'** to be able run this tutorial on a *'normal office laptop'*, i.e. running on windows and with maximum 8GB memory. To do so, we will use a linux VM (running Ubuntu Deslktop) wihtin which we will deploy a `kind` cluster.

The **appendix 0** contains the details for the three deployment scenarios. We will
only describe here how to trigger the automated deployment of the three
approaches.

## 1 - deployment on a Linux laptop

This part covers the first two scenario: deploying a cluster on 3 virtual machines running on the laptop, as well as deploying a cluster on containers.


### 1.1 - Deploying the cluster

The same script called `deploy-cluster.sh` can trigger the automated deployment of both VM-based and container-based clusters:
```
tuto@tuto:~$ cd /projects/learn-kubernetes/
tuto@tuto:/projects/learn-kubernetes/$ ./deploy-cluster.sh
```

If you pass no argument to the script, or if you pass the `-h` (or `--help`) argument, it will display the following message:

```
========================================================================
|  Deploy a 3 nodes Kubernetes cluster                                 |
========================================================================

This script will deploy a 3-nodes Kubernetes cluster. You must indicate
the type of deployment you want:
    ./deploy-cluster.sh 'argument'
where 'argument' is:
    -c, --containers         it will deploy the cluster on containers
    -v, --virtualmachines    it will deploy the cluster on VMs

Please retry with one of these arguments.

========================================================================
|  The END                                                             |
========================================================================
```
As indicated, you can trigger the deployment on VMs with the argument `-v` (or `--virtualmachines`), and the deployment on containers with the argument `-c` (or `--containers`).

This script is actually only running on other shell scripts specialized in only one type of deployment:

|    |    |
| --- | --- |
| `./deploy-cluster-vm/deploy-vm.sh` | for the VMs based deployment |
| `./deploy-cluster-cont/deploy-cont.sh` | for the container-based deployment |

You may also go in the relevant sub-directory and run these scripts directly, without using `deploy-cluster.sh`.

In both case (VMs and containers), you will see at the end of the deployment script that a token (i.e. an apparently meaningless very long line of characters) is displayed and you are invited to copy it, while a browser is launched:

* the browser (possibly you may need to refresh it after few seconds to give time to the cluster to start all services) will show a login page with two option: select the 'Token' box;
![alt txt](./images/tuto-2-dashboard-login-1.png "Dashboard login page")
* paste into the field the token (yeah, its a very long line);
![alt txt](./images/tuto-2-dashboard-login-2.png "Dashboard login page - fill the token")
* and you are logged into the dashboard, which is a web GUI to help you see what is happening in the cluster, and even to operate the cluster from there.
![alt txt](./images/tuto-2-dashboard-overview-1.png "Dashboard - overview of the cluster)")


Have fun with the tutorial!


### 1.2 - Cleanup

The same script called 'cleanup.sh' can trigger the automated cleanup of both VM-based and container-based clusters:
```
tuto@tuto:~$ cd /projects/learn-kubernetes/
tuto@tuto:/projects/learn-kubernetes/$ ./cleanup.sh

    ========================================================================
    |  Cleanup after the Kubernetes tutorial                               |
    ========================================================================

    This script will cleanup after having deployed a 3-nodes Kubernetes
    cluster. You must indicate the type of deployment you want:
        ./cleanup.sh 'argument'
    where 'argument is:
        -c, --containers         it will deploy the cluster on containers
        -v, --virtualmachines    it will deploy the cluster on VMs

    Please retry with one of these arguments.

    ========================================================================
    |  The END                                                             |
    ========================================================================
```

As indicated, you can trigger the cleanup of VMs with the argument `-v` (or `--virtualmachines`), and the cleanup of containers with the argument `-c` (or `--containers`).

This script is actually only switching your action to two other shell scripts
which are each specialized in one type of deployment:

|    |    |
| --- | --- |
| `./deploy-cluster-vm/cleanup-vm.sh` | for the VMs based deployment |
| `./deploy-cluster-cont/cleanup-cont.sh` | for the container-based deployment |

You may also run these two scripts directly, bypassing `cleanup.sh`.


## 2 - deployment on a Windows laptop

The first scenario cannot be run so easily on a Windows platform:
* interacting from the Windows OS with a cluster of 3 VMs running on their own private network is less straightforward (at least for me) than doing it on Linux;
* launching a 4th VM from which running the tutorial would be great, but most laptop will NOT sustain running 4 VMs (actually not all laptop will even be able to run properly 3 VMs as expected here);
* also, it is not possible to run a VM inside a VM (i.e. running a VM relies on accessing the hardware virtualisation capability of the chipset, which is available from the Host system - here Windows - but not from the guest VMs themselves).

So I only propose a *'combi'* scenario where:
* we launch from VirtualBox on Windows a Linux VM, on which all relevant tools are pre-installed;
* create the /projects directory with all open rights (chmod 777);
* copy the tutorial files in this directory:
```
$ cd /projects/
$ git clone https://github.com/tsouche/learn-kubernetes.git
$ cd /projects/learn-kubernetes/
```
* deploy a container-based cluster from within the VMs:
```
$ cd /projects/lean-kubernetes/
$ ./deploy-cluster.sh -c
```
and then you can run the tutorial from here, exactly the same way as described in
Part 1.

The VirtualBox image called `2020-01-06 - Ubuntu 18.04 - tutorial.ova` is
available for download but it is a very large file (almost 7GB) so you should
consider getting it from a USB Key.

Alternatively, you can build a similar image:
* load a clean Ubuntu Desktop 18.04.3 LTS image (directly from Ubuntu servers) staight into VirtualBox;
* install `docker`, `docker-compose`, `docker-machine` in version 18.09;
* install `GO` v1.14 or later, `kind` version 0.8.1;
* install `kubeadm`, `kubectl` and `kubelet` version 16.04. ***versions to be verified***

and you are ready :-)
