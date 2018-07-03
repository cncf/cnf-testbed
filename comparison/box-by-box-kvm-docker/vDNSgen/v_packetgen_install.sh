#!/bin/bash

#Prepare files
cd ~
mkdir vDNSgen
cd vDNSgen
cp /vagrant/v_packetgen_init.sh .
cp /vagrant/vpacketgen.sh .
cp /vagrant/run_streams_dns.sh .
chmod +x v_packetgen_init.sh
chmod +x vpacketgen.sh
chmod +x run_streams_dns.sh

sudo apt-get update -y
sudo apt-get install --allow-unauthenticated -y make wget gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates -y
pip install jsonschema

# Install VPP
export UBUNTU="xenial"
export RELEASE=".stable.1804"
sudo rm /etc/apt/sources.list.d/99fd.io.list
sudo echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | sudo tee -a /etc/apt/sources.list.d/99fd.io.list
sudo apt-get update
sudo apt-get install -y vpp vpp-dpdk-dkms vpp-lib vpp-dbg vpp-plugins vpp-dev
sleep 1

# Run instantiation script
cd /opt
sudo cp -r /vagrant/dns_streams /opt/
sudo cp ~/vDNSgen/v_packetgen_init.sh .
sudo cp ~/vDNSgen/vpacketgen.sh /etc/init.d
sudo update-rc.d vpacketgen.sh defaults

./v_packetgen_init.sh
