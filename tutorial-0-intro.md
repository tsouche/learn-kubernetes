# Learn Kubernetes - Part 0 - Introduction


This tutorial mixes elements from the official Kubernetes site 'get started' sections (many of these), but also from Dada's blog, Mauilion's blog, several Digital Ocean's pages and many other sources over the rich and highly diverse documentation available on Kubernetes, `KinD`, the Dashboard, Ambassador Ingress controller, etc etc... I merely copied and never invented the technology, so I fullheartedly thank them, + a special thanks to the fast, incredibly efficient, warm, welcoming and indulgent support from several people on the `#kind` channel of the Kubernetes community slack: ***thank you!!!*** :smile:


**BE AWARE** that the sole purpose of this tutorial is to get you to practise and understand the basics of Kubernetes, but it does **NOT** give proper guidelines to setup a production environment. Namely, we violate in this tutorial every possible security rule in order to keep things simple, so **DO NOT** setup a production environment this way.


## Read the documents... and have fun

The tutorial is composed of 7 documents (`tutorial-n-title.md` *with 0 =< `n` =< 6*): they will guide you step by step through various exercises which will help you grasp the concepts of Kubernetes by actually executing commands on a Kubernetes cluster. These documents follow a progression, so you'd rather go through them in the logical order:

* **Part 1**: getting to know the basic concepts of Kubernetes
* **Part 2**: setting up a Kubernetes cluster
* **Part 3**: deploying a simple app on this cluster
* **Part 4**: deploying a more complex (and stateful) app on the cluster
* **Part 5**: deploying a stateful app on top of a Cassandra ring on top of Kubernetes
* **Part 6**: conclusion

This tutorial also relies on multiple other documents and files which are available to you in case you want to go deeper in some aspects:

* a sub-directory `./cluster-deploy` contains various configuration files used in the Part 2 for setting up the kubernetes cluster
* a sub-directory `./app-part3` contains the components of a simple 'hello world' application used in Part 3;
* a sub-directory `./app-part4` contains the components of a stateful 'guestbook' application used in Part 4;
* a sub-directory `./app-part5` contains the components of a example of implementation of a cassandra ring ontop kubernetes, used in Part 5.
* several pictures which appear in the Tutorial documents are stored in the `./images` directory;
* and, while structuring this tutorial, I gathered some interesting notes in *Appendices* files which you will find in the `./appendices` directory.


## Pre-requisites and installation of needed software

I have tried to strongly limit the pre-requisites to run this tutorial and actually learn something from this experience: I eventually got to **only one** requirement:

you must have a linux machine (desktop or laptop) with an account with `sudo` privilege (i.e. need to have the admin rights). Ubuntu will be perfect for beginners like me.

From this point onward, we will download the tutorial material and install few software which are required to actually run the tutorial.

### Download the tutorial materials

All the required programs, documents, pictures... are in the git repository, so all you need to do is to create a repository wher eyou will download the git repository (as it is shown on the `README` file).

I suggest you create a `/tuto` directory at the root of the file system, and clone this git repo into it. The following command will do the job:

```bash
sudo rm -rf /tuto && sudo mkdir /tuto && sudo chmod +777 /tuto && cd /tuto && \
    git clone https://github.com/tsouche/learn-kubernetes.git && \
    cd learn-kubernetes
```

Alternatively, you can download the [`prepare.sh`](https://github.com/tsouche/learn-kubernetes/blob/master/prepare.sh "Download 'prepare.sh'") shell script and execute it: it will do the job for you.


### Install the various programs needed to run the tutorial

I assume from now onward that you have created the `/tuto/learn-kubernetes` directory and that all tutorial files are there.

We now need to install:

* `curl` version 7 or above
* `docker` version 19.03 or above
* `Go` version 1.14 or above
* `KinD` version 0.8.1
* `kubectl` version

The shell script `./cluster-deploy/install.sh` will do all this work for you:

```bash
tuto@laptop:/tuto/learn-kubernetes/$ ./cluster-deploy/install.sh
```

This is it. Nothing else is needed... except the desire to learn :smile:. The next step is in [Part 1](./tutorial-1-concepts.md "Part 1 - Kubernetes Concepts") to get acquainted with teh basic concepts of Kubernetes.
