#!/bin/bash

# Reminder: this script is executed as root, at the boot of the VM
# We assume here that the local /vagrant directory is shared with the host directory from where the Vagrantfile is run.
# update the package list
apt-get update


echo " "
echo "================================================="
echo " Install docker"
echo "================================================="
echo " "

# Install docker (as root)
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
# create the user/group to be able to use it as 'vagrant' regular user
groupadd docker
usermod -aG docker vagrant

echo " done"
echo " "
echo "================================================="
echo " Install GO v1.13"
echo "================================================="
echo " "

sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install -y golang-1.13
export PATH=$PATH:/usr/lib/go-1.13/bin

echo " done"
echo " "
echo "================================================="
echo " Install kind v0.6.1"
echo "================================================="
echo " "

# The binary file is available in the shared directory: copy it in t a bin directory
cp /vagrant/kind-v0.6.1-Linux-amd64 /usr/lib/go-1.13/bin/kind
chmod +x /usr/lib/go-1.13/bin/kind

echo " done"
echo " "
echo "================================================="
echo " Install kubectl v1.16.4"
echo "================================================="
echo " "
echo " "

# DO NOT install the latest version, but the version 1.16.4 which is compliant 
# with kind v0.6.1

cp /vagrant/kubectl-v1.16.4-linux-amd64 /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

echo " done"
echo " "
echo "================================================="
echo " Update the PATH (in /etc/profile) for all users"
echo "================================================="
echo " "
echo " "

cat <<EOF >> /etc/profile

PATH=$PATH:/usr/lib/go-1.13/bin/
EOF
source /etc/profile


cat <<EOF >> /home/vagrant/.bashrc

PATH=$PATH:/usr/lib/go-1.13/bin/
EOF

