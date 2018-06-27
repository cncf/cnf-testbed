#!/usr/bin/env bash
set -ex

#cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

#cd ~
#mkdir Pktgen
#cd Pktgen
#cp /vagrant/setup_intel_proxy.sh .
#chmod +x setup_intel_proxy.sh
#sudo ./setup_intel_proxy.sh

sudo apt-get update -y
sudo apt-get install linux-headers-$(uname -r) -y

sudo apt-get remove docker docker-engine docker.io -y
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common -y

#for line in $(cat /etc/environment); do
#  export $line
#done

curl -fsSLv https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
 
sudo apt-get update

sudo apt-get install docker-ce -y

lspci | grep Ethernet

#sudo mkdir -p /etc/systemd/system/docker.service.d
#sudo cp /vagrant/http-proxy.conf /etc/systemd/system/docker.service.d/

#sudo systemctl daemon-reload
#sudo systemctl restart docker

sudo docker pull opnfv/nfvbench

cd ~
mkdir nfvbench
cd nfvbench
cp /vagrant/nfvbench_config.cfg .

sudo docker run --detach --net=host --privileged -v $PWD:/tmp/nfvbench -v /dev:/dev -v /lib/modules/$(uname -r):/lib/modules/$(uname -r) -v /usr/src:/usr/src --name nfvbench opnfv/nfvbench
echo "alias nfvbench='sudo docker exec -it nfvbench nfvbench'" >> ~/.bashrc

sudo docker exec nfvbench sh -c 'make -C /opt/trex/v2.32/ko/src'



