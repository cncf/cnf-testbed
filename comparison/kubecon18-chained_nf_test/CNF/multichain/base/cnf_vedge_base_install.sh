#! /bin/bash

# Prepare files
cd /vEdge
mkdir ~/sockets

apt-get update -y
apt-get --no-install-recommends install -y --allow-unauthenticated make wget gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates vim
pip install jsonschema

# Install VPP
export UBUNTU="xenial"
#export UBUNTU="bionic"
export RELEASE=".stable.1804"
rm /etc/apt/sources.list.d/99fd.io.list
echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | tee -a /etc/apt/sources.list.d/99fd.io.list
apt-get update
apt-get --no-install-recommends install -y vpp vpp-dpdk-dkms vpp-lib vpp-dbg vpp-plugins vpp-dev
sleep 1
