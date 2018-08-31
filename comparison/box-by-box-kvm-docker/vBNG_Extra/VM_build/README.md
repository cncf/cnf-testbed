## Removing an existing box

Remove from Vagrant:
`vagrant box remove vbng`

List volumes:
`virsh vol-list default`
- Names should be: vbng_vagrant_box_image_0.img, VM_build_vbng.img

Remove volumes:
```
virsh vol-delete vbng_vagrant_box_image_0.img --pool default`
virsh vol-delete VM_build_vbng.img --pool default`
virsh undefine VM_build_vbng`
```

Refresh pool:
`virsh pool-refresh default`

Remove .box file
`rm vbng.box`

## Build vbng box

`./build_vm.sh`

The following error will likely show - Just ignore and wait for script to complete

```
virt-sysprep: error: libguestfs error: file receive cancelled by daemon

If reporting bugs, run virt-sysprep with debugging enabled and include the
complete output:

  virt-sysprep -v -x [...]
```

