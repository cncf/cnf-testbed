#!/bin/bash
set -o xtrace  # print commands during script execution

sudo apt-get update -y
sudo apt-get install --allow-unauthenticated -y make wget gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates -y
pip install jsonschema

sudo apt-get -y install linux-headers-$(uname -r)

# Install VPP
export UBUNTU="xenial"
export RELEASE=".stable.1804"
sudo rm /etc/apt/sources.list.d/99fd.io.list
sudo echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | sudo tee -a /etc/apt/sources.list.d/99fd.io.list
sudo apt-get update
sudo apt-get install -y vpp vpp-dpdk-dkms vpp-lib vpp-dbg vpp-plugins vpp-dev
sleep 1

sudo sed -i 's/^.*\(net.ipv4.ip_forward\).*/\1=1/g' /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

get_nic_pci_list() {
  while read -r line ; do
    if [ "$line" != "${line#*network device}" ]; then
      echo -n "${line%% *} "
    fi
  done < <(lspci)
}
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="isolcpus=1,2 nohz_full=1,2 rcu_nocbs=1,2"/g' /etc/default/grub
sudo update-grub2

cp /build/igb_uio.ko /lib/modules/$(uname -r)/kernel/drivers/
echo 'igb_uio' | sudo tee -a /etc/modules
sudo depmod

sh /build/inject_vagrant_ssh_key.sh

# Stop the VPP service before changing the configuration
#sudo service vpp stop
