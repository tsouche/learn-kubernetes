# "learn-kubernetes"


## What is this tutorial about ?

This tutorial aims at guiding a beginner user to learn basic usage of **Kubernetes** by practicing, step-by-step and with details about what to do, and what results to expect, showing real examples in a terminal window. I actually ended-up writing down this tutorial because this is way *I* got to learn about Kubernetes: since I had done the investment to get manually through all the steps as described through this tutorial, I thought it might be of interest to someone else.

The only thing you need to run this tutorial is:

* a Linux powered machine (I typically use a laptop running on Ubuntu);
* a user account with `sudo privilege`;
* an account on *GitHub* and on *DockerHub* is a plus (free account are ok).

The various steps of the tutorial:

1. present the Kubernetes concepts
1. deploy a local cluster with `KinD` (Kubernetes in Docker): K8s, Dashboard, Ingress...
1. deploy and play with a very simple stateless application ("Hello World!")
1. deploy, scale, upgrade a stateful application, showing first results and limits on resilience
1. deploy a stateful application using Cassandra datastore as a backend, and show resilience

... and once you have reached this point, you may be interested in getting into *real* production topics with Kubernetes, and you will then need to pursue with much more serious tutorials, on real infrastructure.

## How do I start ?

To get started, you should choose a directory from which you will run this tutorial: I suggest you create a `/tuto` directory at the root of the file system, and clone this git repo into it.

```bash
sudo mkdir /tuto && sudo chmod +777 /tuto && cd /tuto && \
    git clone https://github.com/tsouche/learn-kubernetes.git && \
    cd learn-kubernetes
```

In case you see it usefull, [this shell script](./prepare.sh "Create a directory and download the tutorial into it") will do the job for you: just run it in a terminal window.

If you prefer to start reading the documentation online before, be my guest: the documentation starts [here](./tutorial-1-concepts.md "Tutorial Part 0") (and post feedbacks so that it is further improved :smile:).
