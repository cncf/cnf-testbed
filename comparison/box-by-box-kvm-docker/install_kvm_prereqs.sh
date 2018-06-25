#!/bin/bash

VAGRANT_VERSION="2.1.1"
VAGRANT_DEB="vagrant_${VAGRANT_VERSION}_x86_64.deb"
VAGRANT_DEB_URL="https://releases.hashicorp.com/vagrant/2.1.1/${VAGRANT_DEB}"

# Install Vagrant from HashiCorp - https://www.vagrantup.com/downloads.html
pushd /tmp
wget -nc -L ${VAGRANT_DEB_URL}
dpkg -i "${VAGRANT_DEB}"
popd


## Install vagrant libvirt plugin - https://github.com/vagrant-libvirt/vagrant-libvirt

apt-get update
## Ubuntu 18.04 does not have source repos enabled, but does not seem to need them for the libvirt plugin
#apt-get build-dep vagrant ruby-libvirt
apt-get install -y qemu libvirt-bin ebtables dnsmasq
apt-get install -y libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev

vagrant plugin install vagrant-libvirt
