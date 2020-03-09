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
sudo apt-get --no-install-recommends install -y linux-headers-$(uname -r) -y

sudo apt-get remove docker docker-engine docker.io -y
sudo apt-get --no-install-recommends install -y \
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

sudo apt-get --no-install-recommends install -y docker-ce -y

lspci | grep Ethernet

#sudo mkdir -p /etc/systemd/system/docker.service.d
#sudo cp /vagrant/http-proxy.conf /etc/systemd/system/docker.service.d/

#sudo systemctl daemon-reload
#sudo systemctl restart docker

sudo docker pull opnfv/nfvbench:1.5.2

cd ~
mkdir nfvbench
cd nfvbench
cp ~/nfvbench_config.cfg .

sudo mkdir /opt/nfvbench

sudo docker run --detach --net=host --privileged -v $PWD:/tmp/nfvbench -v /dev:/dev -v /lib/modules/$(uname -r):/lib/modules/$(uname -r) -v /usr/src:/usr/src --name nfvbench opnfv/nfvbench:1.5.2
echo "alias nfvbench='sudo docker exec -it nfvbench nfvbench -c /tmp/nfvbench/nfvbench_config.cfg'" | sudo tee --append /root/.bashrc
echo "alias nfvbench='sudo docker exec -it nfvbench nfvbench -c /tmp/nfvbench/nfvbench_config.cfg'" | tee --append ~/.bashrc

sudo docker exec nfvbench sh -c 'make -C /opt/trex/v2.32/ko/src'

nfvbench_dir="/proc/$(sudo docker inspect --format {{.State.Pid}} nfvbench)/root/nfvbench"
sudo sed -i -e '191,193d' ${nfvbench_dir}/nfvbench/traffic_gen/trex.py
sudo sed -i '191i\            STLVmFixIpv4(offset="IP")' ${nfvbench_dir}/nfvbench/traffic_gen/trex.py
sudo sed -i '45s/STLVmFixChecksumHw/STLVmFixIpv4/' ${nfvbench_dir}/nfvbench/traffic_gen/trex.py


