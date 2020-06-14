#!/bin/bash


# Configure the keyboard layout to French
apt-get install -y x11-xkb-utils
setxkbmap fr
echo "setxkbmap us" >> ~/.bashrc

#if [ -f "keyboard" ]
#then
#  rm keyboard
#fi
#cat <<EOF>> keyboard
#XKBLAYOUT=fr
#BACKSPACE=guess
#EOF

# Install git and curl

apt-get install -y git
apt-get install -y curl

# Install docker

apt-get update
apt-get install -y apt-transport-https ca-certificates gnupg-agent \
  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

systemctl enable docker
systemctl start docker

groupadd docker
usermod -aG docker vagrant

# install `kind` v0.8.1
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.8.1/kind-$(uname)-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

# install `kubectl` v1.18.2
curl -LO ./kubectl https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl


