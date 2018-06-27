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

Find the vagrant image: `virsh domblklist vDNS_vDNS`

Note the image path.  Eg. `/var/lib/libvirt/images/vDNS_vDNS.img`

Note the folder where the image is.  Eg. `/var/lib/libvirt/images`

From the vagrant_box_data folder copy the following files
- metadata.json
- Vagrantfile
to the folder found above

Change to the folder where the image is.  (`cd /var/lib/libvirt/images`)

Convert the image to qcow format with qemu-convert and rename it to have a ".img" extension.  Eg.

```
qemu-img convert -f raw -O qcow2 vDNS_vDNS.img vDNS.qcow2
mv vDNS.qcow2 vDNS.img
```

Package the new image, meta data and Vagratfile:

```
tar zcvf vDNS-$(date +%Y%m%d-%H%M).box ./metadata.json ./Vagrantfile ./vDNS.img
```

To use the box in vagrant you will need to add it with the following command: vagrant box add --name BOX_NAME PATH_TO_BOX

Example:

```
vagrant box add --name vDNS-p2a ~/vDNS-20180627-2133.box
```

It can then be used from your Vagrantfile
