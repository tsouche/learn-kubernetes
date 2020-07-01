#!/bin/bash


# Install git and curl
sudo apt-get install -y git
sudo apt-get install -y curl

# Install go version 1.14.2 or later

sudo apt-get install -y golang

# Install docker

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg-agent \
  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo systemctl enable docker
sudo systemctl start docker

sudo groupadd docker
sudo usermod -aG docker vagrant

# install `kind` v0.8.1
sudo cp ./cluster-deploy/kind-linux-amd64-v0.8.1 /usr/local/bin/kind

# install `kubectl` v1.18.2
sudo cp ./cluser-deploy/kubectl-linux-amd64-v1.18.2 /usr/local/bin/kubectl
