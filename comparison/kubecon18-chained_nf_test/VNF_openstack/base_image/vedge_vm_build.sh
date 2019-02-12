#!/bin/bash
set -o xtrace  # print commands during script execution

sudo apt-get update -y
sudo apt-get install --allow-unauthenticated -y make gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates
pip install jsonschema

sudo apt-get -y install linux-headers-$(uname -r)

# Install VPP
VPP_VERSION="18.10-release"
artifacts=()
vpp=(vpp vpp-dbg vpp-dev vpp-lib vpp-plugins)
if [ -z "${VPP_VERSION-}" ]; then
    artifacts+=(${vpp[@]})
else
    artifacts+=(${vpp[@]/%/=${VPP_VERSION-}})
fi
curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
apt-get install -y "${artifacts[@]}"
sleep 1

sudo sed -i 's/^.*\(net.ipv4.ip_forward\).*/\1=1/g' /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="isolcpus=1,2 nohz_full=1,2 rcu_nocbs=1,2"/g' /etc/default/grub
sudo update-grub2

cp /opt/igb_uio.ko /lib/modules/$(uname -r)/kernel/drivers/
echo 'igb_uio' | sudo tee -a /etc/modules
sudo depmod
sudo modprobe igb_uio
