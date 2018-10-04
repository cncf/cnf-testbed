**Build vEdge box (base image)**

Run `./build_vm.sh` and wait for it to complete

The following error will likely show - Just ignore and wait for script to complete

```
virt-sysprep: error: libguestfs error: file receive cancelled by daemon

If reporting bugs, run virt-sysprep with debugging enabled and include the
complete output:

  virt-sysprep -v -x [...]
```

*Upload Openstack vEdge image**
Run the below to convert the vagrant image to qcow2 format for use with Openstack
```
cp /root/.vagrant.d/boxes/vedge/0/libvirt/box.img ./vedge.img
```

Next upload the image to openstack
```
wget http://cloud-images.ubuntu.com/xenial/20180919/xenial-server-cloudimg-amd64-disk1.img
openstack image create --disk-format qcow2 --container-format bare --public --file ./vedge.img vedge-image
```

**Remove existing vEdge box**

Run `./build_vm.sh clean`
