# Appendix 1 - Build the tutorial's docker images


## A - Hello application

In Part 3 of the tutorial, we deploy a very simple app showing a 'Hello world' message and the `ContainerID` of the container in which it runs (it is a simpler version of the app used in the previous docker tutorial, without redis).

We will show here how to build it, knowing that all necessary resources are the python script, the requirements and the `Dockerfile`: they all are in the `./app-hello` sub-directory. Let's build the app, and upload the container in DockerHub, so that we can use it later in the tutorial (for more details on the step-by-step process, you can refer to the docker tutorial).

```
tuto@laptop:$~/learn-kubernetes$ cd app-hello

tuto@laptop:$~/learn-kubernetes/app-hello$ ls
app.py  Dockerfile  requirements.txt

tuto@laptop:$~/learn-kubernetes/app-hello$ docker build -t app-hello .
Sending build context to Docker daemon  4.096kB
Step 1/7 : FROM python:3.6
3.6: Pulling from library/python
[...]
Successfully tagged app-hello:latest

tuto@laptop:$~/learn-kubernetes/app-hello$ docker login
Login Succeeded

tuto@laptop:$~/learn-kubernetes/app-hello$ docker tag app-hello tsouche/learn-kubernetes:part3

tuto@laptop:$~/learn-kubernetes/app-hello$ docker image ls
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
app-hello                  latest              d653bc179719        3 minutes ago       923MB
tsouche/learn-kubernetes   part3               d653bc179719        3 minutes ago       923MB
python                     3.6                 138869855e44        4 days ago          913MB

tuto@laptop:$~/learn-kubernetes/app-hello$ docker push tsouche/learn-kubernetes:part3
The push refers to repository [docker.io/tsouche/learn-kubernetes]
c256e8ea6e29: Pushed
[...]
dd5242c2dc8a: Mounted from library/python
part3: digest: sha256:11a4499466b92f3907e369d07ba943b0a600e417f94cac0ff13ec07e82727d61 size: 2843
```

Here it is: the image is uploaded to DockerHub and we can now test it locally (i.e. not running on the Kubernetes cluster, but simply running on a local docker container):

```
tuto@laptop:$~/learn-kubernetes/app-hello$ docker run -d -p 4000:80 tsouche/learn-kubernetes:part3
6de75d8df9562f7870cda1bd691deb0d67d9b8c7763383c777c5bef235664ce2
```

It is now running, and the web server is listening on the port 4000. Let's probe the URL using `curl`:

```
tuto@laptop:$~/learn-kubernetes/app-hello$ curl http://localhost:4000
<h3>Hello World!</h3><b>Hostname:</b> 6de75d8df956<br/>tuto@laptop:$~/learn-kubernetes/app-hello$
```

Here we are: the container is published on Docker Hub, and the application is running properly, displaying the 'Hello World' message and the ID of the container in which it runs.

We also do the same for the version 2 of the app, whose components are located in the 'v2' sub-directory:

```
$ cd v2/
$ docker build -t app-hello-v2 .
$ docker tag app-hello-v2 tsouche/learn-kubernetes:part3v2
$ docker push tsouche/learn-kubernetes:part3v2
```

This is how the Docker images were built, available to be used in this tutorial.
