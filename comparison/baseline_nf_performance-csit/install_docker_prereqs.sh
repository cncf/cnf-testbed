#!/bin/bash

sudo apt-get update

sudo apt-get --no-install-recommends install -y  \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository -y  \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get --no-install-recommends install -y docker-ce

# Prepare Hugepages
echo "Setting up hugepages memory support"
for i in $(ls /sys/devices/system/node/ | grep node); do
  if [ ! "$(sudo cat /sys/devices/system/node/${i}/hugepages/hugepages-2048kB/nr_hugepages)" == "4096" ]; then
    sudo echo 4096 > /sys/devices/system/node/${i}/hugepages/hugepages-2048kB/nr_hugepages
  fi
done

if [ ! -d "/dev/hugepages" ]; then
  sudo mount -t hugetlbfs -o pagesize=2M none /dev/hugepages
fi 
