!#/bin/bash

if [ -d "/tuto" ]
then
  sudo rm -rf /tuto
fi

sudo mkdir /tuto
sudo chmod +777 /tuto
cd /tuto
git clone https://github.com/tsouche/learn-kubernetes.git
cd learn-kubernetes
