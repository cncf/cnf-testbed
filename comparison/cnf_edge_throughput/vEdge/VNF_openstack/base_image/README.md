**Build vEdge box (base image)**

Run `./build_vm.sh` and wait for it to complete

The following error will likely show - Just ignore and wait for script to complete

```
virt-sysprep: error: libguestfs error: file receive cancelled by daemon

If reporting bugs, run virt-sysprep with debugging enabled and include the
complete output:

  virt-sysprep -v -x [...]
```

**Build & Upload Openstack vEdge qcow image**
Run the below to convert the vagrant image to qcow2 format for use with Openstack
```
sudo qemu-img convert -f raw -O qcow2 /root/.vagrant.d/boxes/vedge/0/libvirt/box.img vedge.qcow2
```

Next upload the image to openstack
```
openstack image create --disk-format qcow2 --container-format bare --public --file ./vedge.qcow2 vedge-image
```

**Remove existing vEdge box**

Run `./build_vm.sh clean`
