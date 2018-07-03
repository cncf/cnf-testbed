# vDNS VNF VM creation

Build a vagrant box with libvirt support

The VNF/CNF is using Bind9 and Kea DHCP

The setup scripts are originally from https://github.com/onap/demo/blob/master/vnfs/vCPE/scripts

### Build the VM

Install plugin to support disk resizing

`vagrant plugin install vagrant-disksize`

Build the VM with vagrant

`vagrant up vDNS`

After it completes, shutdown the vm without destroying the vagrant image

`vagrant halt vDNS`

### Create a vagrant box from the VM

Find the vagrant image: `virsh domblklist vDNS_vDNS`

Note the image path.  Eg. `/var/lib/libvirt/images/vDNS_vDNS.img`

Note the folder where the image is.  Eg. `/var/lib/libvirt/images`

Change to the folder where the image is.  (`cd /var/lib/libvirt/images`)

Run the `create_box.sh` script from the repo specifying the image and the new vagrant box name.

```
~/cnfs/tools/create_box.sh vm_build_vDNS.img vDNS15
```

To use the box in vagrant you will need to add it with the following command: vagrant box add --name BOX_NAME PATH_TO_BOX

Example:

```
vagrant box add vDNS15 --name vDNS15
```

It can then be used from your Vagrantfile
