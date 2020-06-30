# Learn Kubernetes Basics - Part 0 - pre-requisites


This tutorial mixes elements from the official Kubernetes site 'get started' sections (many of these), but also from Dada's blog (specifically for setting up the Kubernetes clusters on VMs running on a laptop) and other blogs. Main links are:
    [https://kubernetes.io/docs/tutorials/kubernetes-basics/](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
    [https://www.dadall.info/article658/preparer-virtualbox-pour-kubernetes](https://www.dadall.info/article658/preparer-virtualbox-pour-kubernetes)
    [https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
    [https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)



**BE AWARE** that the sole purpose of this tutorial is to get you to practise and understand the basics of Kubernetes, but it does NOT give proper guidelines to setup a production environment. Namely, we violate in this tutorial every possible security rule in order to keep things simple, so **DO NOT** setup a production environment this way.


The tutorial will guide you step by step through:

* **Part 1**: getting to know the basic concepts of Kubernetes
* **Part 2**: setting up a Kubernetes cluster
* **Part 3**: deploying a simple app on this cluster
* **Part 4**: deploying a more complex (and stateful) app on the cluster
* **Part 5**: deploying a stateful app on top of a Cassandra ring on top of Kubernetes
* **Part 6**: conclusion

This tutorial is structured in several documents + many other files:

* various pictures whose name point back to the structure of this document, and which are usefull to understand better the Kubernetes concepts or to illustrate some results to be obtained during the execution of the tutorial;
* a sub-directory `deploy` contains various configuration files used in the Part 2 for setting up the kubernetes cluster
* a sub-directory `app-hello` contains the components of a simple 'hello world' application used in Part 3;
* a sub-directory `app-guestbook` contains the components of a stateful 'guestbook' application used in Part 4;
* a sub-direcotry `app-cassandra` contains the components of a example of implementation of a cassandra ring ontop kubernetes, used in Part 5.

Here are the identified pre-requisites to run this tutorial and actually learn something from this experience:

* have a linux laptop, and an account with `sudo` privilege (i.e. need to have the admin rights). Ubuntu will be perfect for beginners.
* have `curl`, `git` and `virtualbox` installed.
* have `go` and `kind` installed.

Also, you will find several resources by cloning the git repository:
`git clone https://github.com/tsouche/learn-kubernetes.git`


This is it. Nothing else is needed... except the desire to learn :smile:
