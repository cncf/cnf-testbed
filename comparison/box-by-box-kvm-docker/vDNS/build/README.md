# vDNS VNF VM creation

Build a vagrant box with libvirt support

The VNF/CNF is using Bind9 and Kea DHCP

The setup scripts are originally from https://github.com/onap/demo/blob/master/vnfs/vCPE/scripts

### Build the VM

Build the VM with vagrant

`vagrant up vDNS`

After it completes, shutdown the vm without destroying the vagrant image

`vagrant halt vDNS`

### Create a vagrant box from the VM

Pre-req:
- install virt-sysprep. For ubuntu that is in the package "libguestfs-tools"

Use the vagrant package command to create a vagrant box. Ex:

```
vagrant package --output vDNS.box vDNS
```

To use the box in vagrant you will need to add it with the following command: vagrant box add --name BOX_NAME PATH_TO_BOX

Example:

```
vagrant box add vDNS.box --name vDNS
```

It can then be used from your Vagrantfile

#### Updating the saved VM

Vagrant only supports box versioning for those adding from Vagrant
Cloud or a custom box host -- not from a local file.

To update you will need to remove the old box and image. Example:

- `vagrant box remove vDNS`
- `rm /var/lib/libvirt/images/vDNS_vagrant_box_image_0.img`
