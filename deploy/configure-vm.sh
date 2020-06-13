#!/bin/bash


echo "======================================================================="
echo "|  Initial configuration of the VM (tso_base_ubuntu_20.04.sh)         |"
echo "======================================================================="
echo "..."

# We assume that the VM is 'fresh' (i.e. from a bare Ubuntu 20.04 image)

# refresh the packages

echo "======================================================================="
echo "Refresh all packages lists"
echo "======================================================================="
echo "..."

apt-get update
#apt-get upgrade -y
apt-get install curl
apt-get install git

# create the use 'tuto' with 'tutorial' as password, and grant him sudo 
# privilege

echo "======================================================================="
echo " Create user 'tuto'"
echo "======================================================================="
echo "..."

echo "install open SSL"
apt-get install -y libssl-dev
# use open SSL to create the password hash which will be fed into useradd
PWD_HASH=$(echo 'tuto' | openssl passwd -1 -stdin)
useradd --home /home/tuto/ --create-home --shell /bin/bash \
	--password $PWD_HASH tuto
# useradd --home /home/tuto/ --create-home --shell /bin/bash --password $1$DCAWy5p7$NuOQUajtuxa5yQqHQa6iU.  tuto
usermod -aG sudo tuto

echo "..."
echo "done"
echo "..."

# install docker and run it as a service

echo "======================================================================="
echo " Install docker"
echo "======================================================================="
echo "..."

apt-get update
apt-get install -y docker.io
systemctl enable docker && systemctl start docker

groupadd docker
usermod -aG docker tuto

echo "..."
echo "done"
echo "..."


echo "======================================================================="
echo " Copy the tutorial resources"
echo "======================================================================="
echo "..."

cd /home/tuto/
git clone https://github.com/tsouche/learn-kubernetes.git
cd learn-kubernetes/

echo "..."
echo "done"
echo "..."


echo "======================================================================="
echo " Install kind and kubernetes"
echo "======================================================================="
echo "..."

cp ./deploy/kind-linux-amd64-v0.8.1 ./deploy/kind
chmod +x ./deploy/kind
mv ./deploy/kind /usr/local/bin/kind

cp ./deploy/kubectl-linux-amd64-v1.18.2 ./deploy/kubectl
chmod +x ./deploy/kubectl
mv ./deploy/kubectl /usr/local/bin/kubectl


echo "..."
echo "done"
echo "..."


echo "======================================================================="
echo " The END (tso_base_ubuntu_20.04.sh)"
echo "======================================================================="
