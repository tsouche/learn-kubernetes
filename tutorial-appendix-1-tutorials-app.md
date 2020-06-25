# Appendix 1 - Build the tutorial's docker images


## A - Part 3 - Hello application

In Part 3 of the tutorial, we deploy a very simple python web application displaying a 'Hello world' message and the `ContainerID` of the container in which it runs. We actually use two versions of the application in order to demonstrate how Kubernetes manages the lifecycle of applications.

We will show here how to build the corresponding docker images, knowing that all necessary resources are the python script `app-part3-vX.py`, the requirements file `requirements.txt` and the `Dockerfile`: they all are in the `./app-part3/v1` and `./app-part3/v2` sub-directories. Let's build the two versions of the applications, and upload the containers in DockerHub, so that we can use it later in the tutorial (for more details on the step-by-step process, you can refer to the **learn docker** tutorial).

```bash
tuto@laptop:$~/learn-kubernetes$ docker login
Username: tsouche
Password:
Login Succeeded

tuto@laptop:$~/learn-kubernetes$ cd app-part3/v1

tuto@laptop:$~/learn-kubernetes/app-part3/v1$ ls
app-part3-v1.py  Dockerfile  requirements.txt

tuto@laptop:$~/learn-kubernetes/app-part3/v1$ docker build -t app-part3v1 .
Sending build context to Docker daemon  4.096kB
Step 1/7 : FROM python:3.6
3.6: Pulling from library/python
[...]
Successfully tagged app-part3-v1:latest

tuto@laptop:$~/learn-kubernetes/app-part3/v1$ docker tag app-part3-v1 tsouche/learn-kubernetes:part3

tuto@laptop:$~/learn-kubernetes/app-part3/v1$ docker image ls
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
app-part3-v1               latest              11b58e2759e4        About a minute ago   924MB
tsouche/learn-kubernetes   part3v1             11b58e2759e4        About a minute ago   924MB
python                     3.6                 2dfb6d103623        5 weeks ago          914MB

tuto@laptop:$~/learn-kubernetes/app-part3/v1$ docker push tsouche/learn-kubernetes:part3
The push refers to repository [docker.io/tsouche/learn-kubernetes]
The push refers to repository [docker.io/tsouche/learn-kubernetes]
6df505cee030: Pushed
df53140b3f99: Pushed
6a5fb16af72b: Pushed
aaeecd3bafff: Mounted from library/python
4ecefce7ec49: Mounted from library/python
3125d8e4d0be: Mounted from library/python
ca5c6919ea52: Mounted from library/python
8c39f7b1a31a: Mounted from library/python
88cfc2fcd059: Mounted from library/python
760e8d95cf58: Mounted from library/python
7cc1c2d7e744: Mounted from library/python
8c02234b8605: Mounted from library/python
part3v1: digest: sha256:c431a4859e82a37660719793a8f745ca116ea3c4c4445f554cb68f99b1e6e786 size: 2843
```

Here it is: the image is uploaded to DockerHub and we can now test it locally (i.e. not running on the Kubernetes cluster, but simply running on a local docker container):

```bash
tuto@laptop:$~/learn-kubernetes/app-part3/v1$ docker run -d -p 4000:80 tsouche/learn-kubernetes:part3v1
7c8fec3ae3434bd7ae32de70a83e9b839e7803dce5ce6ce8f706cbba33f808dd
```

It is now running, and the web server is listening on the port 4000. Let's probe the URL using `curl`:

```bash
tuto@laptop:$~/learn-kubernetes/app-part3/v1$ curl http://localhost:4000
<h3>Hello World! - application version 1</h3><b>Hostname:</b> 7c8fec3ae343<br/>
```

Here we are: the container is published on Docker Hub, and the application is running properly, displaying the 'Hello World' message, the application version and the ID of the container in which it runs.

We also do the same for the version 2 of the app, whose components are located in the 'v2' sub-directory:

```bash
tuto@laptop:$~/learn-kubernetes/app-part3/v1$ cd ../v2/
tuto@laptop:$~/learn-kubernetes/app-part3/v2$ docker build -t app-part3-v2 .
tuto@laptop:$~/learn-kubernetes/app-part3/v2$ docker tag app-part3-v2 tsouche/learn-kubernetes:part3v2
tuto@laptop:$~/learn-kubernetes/app-part3/v2$ docker push tsouche/learn-kubernetes:part3v2
```
and the same way we now check that the image is ok by running the application:

```bash
tuto@laptop:$~/learn-kubernetes/app-part3/v2$ docker container ls
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS              PORTS                  NAMES
7c8fec3ae343        tsouche/learn-kubernetes:part3v1   "python app-part3-v1…"   2 minutes ago       Up 2 minutes        0.0.0.0:4000->80/tcp   agitated_lovelace

tuto@laptop:$~/learn-kubernetes/app-part3/v2$ docker stop 7c8fec3ae343
7c8fec3ae343

tuto@laptop:$~/learn-kubernetes/app-part3/v2$ docker run -d -p 4000:80 tsouche/learn-kubernetes:part3v2
7c8fec3ae3434bd7ae32de70a83e9b839e7803dce5ce6ce8f706cbba33f808dd

tuto@laptop:$~/learn-kubernetes/app-part3/v2$ curl http://localhost:4000
<h3>Hello World! - application version 2</h3><b>Hostname:</b> fbf12c095d73<br/>
```

## B - Part 4 - Hello application with a persistent counter

In Part 4 of the tutorial, we deploy a slightly more complex python web application than in Part 3: it displays a 'Hello world' message, the `ContainerID` of the container in which it runs, and a increments a counter each time the web page is visited (one single counter shared across all the instances of the application). The counter is stored in a Redis database, hosted on a Redis backend service shared by all the web frontend instances.

We will show here how to build the corresponding docker image, knowing that all necessary resources are the python script `app-part4.py`, the requirements file `requirements.txt` and the `Dockerfile`: they all are in the `./app-part4` sub-directory. Let's build the application image, and upload the container in DockerHub, so that we can use it later in the tutorial.

```bash
tuto@laptop:$~/learn-kubernetes$ docker login
Username: tsouche
Password:
Login Succeeded

tuto@laptop:$~/learn-kubernetes$ cd app-part4

tuto@laptop:$~/learn-kubernetes/app-part4$ ls
app-part4.py  frontend-deployment.yaml  redis-master-deployment.yaml  redis-slave-deployment.yaml  requirements.txt
Dockerfile    frontend-service.yaml     redis-master-service.yaml     redis-slave-service.yaml

tuto@laptop:$~/learn-kubernetes/app-part4$ docker build -t app-part4 .
Sending build context to Docker daemon  13.82kB
Step 1/7 : FROM python:3.6
 ---> 2dfb6d103623
[...]
Successfully tagged app-part4:latest

tuto@laptop:$~/learn-kubernetes/app-part4$ docker tag app-part4 tsouche/learn-kubernetes:part4

tuto@laptop:$~/learn-kubernetes/app-part4$ docker image ls
REPOSITORY                 TAG                 IMAGE ID            CREATED              SIZE
app-part4                  latest              e25c69106779        About a minute ago   924MB
tsouche/learn-kubernetes   part4               e25c69106779        About a minute ago   924MB
python                     3.6                 2dfb6d103623        5 weeks ago          914MB

tuto@laptop:$~/learn-kubernetes/app-part4$ docker push tsouche/learn-kubernetes:part4
The push refers to repository [docker.io/tsouche/learn-kubernetes]
a34c64c699f5: Pushed
a1408f25b712: Pushed
6a5fb16af72b: Layer already exists
aaeecd3bafff: Layer already exists
4ecefce7ec49: Layer already exists
3125d8e4d0be: Layer already exists
ca5c6919ea52: Layer already exists
8c39f7b1a31a: Layer already exists
88cfc2fcd059: Layer already exists
760e8d95cf58: Layer already exists
7cc1c2d7e744: Layer already exists
8c02234b8605: Layer already exists
part4: digest: sha256:71d31e3ac9133622fc31b3efec48d913bed03217aa067765f17e815e0e991642 size: 2844
```

Here it is: the image is uploaded to DockerHub and we can now test it locally (i.e. not running on the Kubernetes cluster, but simply running on a local docker container):

```bash
tuto@laptop:$~/learn-kubernetes/app-part4$ docker run -d -p 4000:80 tsouche/learn-kubernetes:part4
88403532e44c60dfba280cce3d596e4018d36041f9290c0ae08e7dd98441aec5
```

It is now running, and the web server is listening on the port 4000. Let's probe the URL using `curl`:

```bash
tuto@laptop:$~/learn-kubernetes/app-part4$ curl http://localhost:4000
<h3>Hello World!</h3><b>Hostname:</b> 88403532e44c<br/><b>Visits:</b> <i>cannot connect to Redis, counter disabled</i>
```

Here we are: the container is published on Docker Hub, and the application is running, displaying the 'Hello World' message, the ID of the container in which it runs and indicating that the Redis database is not accessible (which is normal because we did not isntantiate the Redis service).
