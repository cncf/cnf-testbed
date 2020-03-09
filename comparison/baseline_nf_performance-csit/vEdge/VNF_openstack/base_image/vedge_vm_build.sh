#!/bin/bash

VEDGE_STATE=$(cat /opt/config/vedge_state.txt)

set -o xtrace  # print commands during script execution

if [ "$VEDGE_STATE" == "build" ];
then 
    sudo apt-get update -y
    sudo apt-get --no-install-recommends install -y --allow-unauthenticated -y make wget gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates -y
    pip install jsonschema

    sudo apt-get --no-install-recommends install -y linux-headers-$(uname -r)

    # Install VPP
    export UBUNTU="xenial"
    export RELEASE=".stable.1804"
    sudo rm /etc/apt/sources.list.d/99fd.io.list
    sudo echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | sudo tee -a /etc/apt/sources.list.d/99fd.io.list
    sudo apt-get update
    sudo apt-get --no-install-recommends install -y vpp vpp-dpdk-dkms vpp-lib vpp-dbg vpp-plugins vpp-dev
    sleep 1

    sudo sed -i 's/^.*\(net.ipv4.ip_forward\).*/\1=1/g' /etc/sysctl.conf
    sudo sysctl -p /etc/sysctl.conf

    sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="isolcpus=1,2 nohz_full=1,2 rcu_nocbs=1,2"/g' /etc/default/grub
    sudo update-grub2
else
    echo "Build already complete, skip"
fi
