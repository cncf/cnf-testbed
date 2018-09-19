#!/bin/sh

input="$1"

if [ "$input" == "clean" ]; then
  vagrant box remove vedge
  virsh vol-delete vedge_vagrant_box_image_0.img --pool default
  virsh undefine vedge_vagrant_box_image_0
  virsh pool-refresh default
  rm -f vedge.box
fi


if [ -z "$(vagrant plugin list |grep disksize)" ] ; then
  vagrant plugin install vagrant-disksize
fi

SUDO=$(which sudo)

if [ -z "$(which virt-sysprep)" ] ; then
  $SUDO apt-get install -y libguestfs-tools
fi

# Build the VM with vagrant
vagrant up vedge
vagrant reload 

# After it completes, shutdown the vm without destroying the vagrant image
vagrant halt vedge

# Create a vagrant box from the VM
vagrant package --output vedge.box vedge
vagrant box add vedge.box --name vedge
