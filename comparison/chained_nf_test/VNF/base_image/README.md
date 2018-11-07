**Build vEdge box (base image)**

Run `./build_vm.sh` and wait for it to complete

The following error will likely show - Just ignore and wait for script to complete

```
virt-sysprep: error: libguestfs error: file receive cancelled by daemon

If reporting bugs, run virt-sysprep with debugging enabled and include the
complete output:

  virt-sysprep -v -x [...]
```

**Remove existing vEdge box**

Run `./build_vm.sh clean`
