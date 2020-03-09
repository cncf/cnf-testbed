#!/bin/sh

if [ -z "$(vagrant plugin list |grep disksize)" ] ; then
  vagrant plugin install vagrant-disksize
fi

SUDO=$(which sudo)

if [ -z "$(which virt-sysprep)" ] ; then
  $SUDO apt-get --no-install-recommends install -y libguestfs-tools
fi

#Build the VM with vagrant
vagrant up vDNS

#After it completes, shutdown the vm without destroying the vagrant image
vagrant halt vDNS

### Create a vagrant box from the VM

vagrant package --output vDNS.box vDNS


# To rebuild do the following:
# - vagrant box remove vDNS
# - rm /var/lib/libvirt/images/vDNS_vagrant_box_image_0.img
