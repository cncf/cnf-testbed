#! /bin/bash

if [ -z "$(vagrant plugin list |grep disksize)" ] ; then
	  vagrant plugin install vagrant-disksize
  fi

  SUDO=$(which sudo)

  if [ -z "$(which virt-sysprep)" ] ; then
	    $SUDO apt-get install -y libguestfs-tools
    fi

    #Build the VM with vagrant
    vagrant up vbng
    vagrant reload 

    #After it completes, shutdown the vm without destroying the vagrant image
    vagrant halt vbng

    ### Create a vagrant box from the VM

    vagrant package --output vbng.box vbng

    vagrant box add vbng.box --name vbng

    # To rebuild do the following:
    # - vagrant box remove vDNS
    # - rm /var/lib/libvirt/images/vDNS_vagrant_box_image_0.img
