#!/bin/bash

VAGRANT_VERSION="2.1.2"
VAGRANT_DEB="vagrant_${VAGRANT_VERSION}_x86_64.deb"
VAGRANT_DEB_URL="https://releases.hashicorp.com/vagrant/2.1.2/${VAGRANT_DEB}"

# Install Vagrant from HashiCorp - https://www.vagrantup.com/downloads.html
pushd /tmp
wget -nc -L ${VAGRANT_DEB_URL}
dpkg -i "${VAGRANT_DEB}"
popd

## Install vagrant libvirt plugin - https://github.com/vagrant-libvirt/vagrant-libvirt

apt-get update
## Ubuntu 18.04 does not have source repos enabled, but does not seem to need them for the libvirt plugin
#apt-get build-dep vagrant ruby-libvirt
apt-get --no-install-recommends install -y qemu libvirt-bin ebtables dnsmasq
apt-get --no-install-recommends install -y libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev

vagrant plugin install vagrant-libvirt --plugin-version 0.0.43
vagrant plugin install vagrant-disksize --plugin-version 0.1.2

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

## Workaround to allow access to host sockets
## Disables use of security driver for libvirt (QEMU) and sets user and group to root
sed -i 's/#security_driver = "selinux"/security_driver = "none"/g' /etc/libvirt/qemu.conf
sed -i 's/#user = "root"/user = "root"/g' /etc/libvirt/qemu.conf
sed -i 's/#group = "root"/group = "root"/g' /etc/libvirt/qemu.conf
service libvirtd restart
