# vBNG VNF

Virtualized Broadband Network Gateway

The setup scripts are originally from https://github.com/onap/demo/blob/master/vnfs/vCPE/scripts

### VNF VM setup/testing

Should ideally be started from box-by-box-kvm-docker directory:
`./vBNG_vm_test.sh`

Alternatively it can be started from this (vBNG) directory
`./run_vm.sh`

### Troubleshooting

If `vagrant up` fails to start with vhost sockets attached, showing the following error:
```
There was an error talking to Libvirt. The error message is shown
below:

Call to virDomainCreateWithFlags failed: internal error: process exited while connecting to monitor: 2018-08-24T20:31:24.446153Z qemu-system-x86_64: -chardev socket,id=charnet1,path=/var/run/vpp/sock1.sock: Failed to connect socket /var/run/vpp/sock1.sock: Permission denied
```
You will need to update libvirt to run as root:
- Open /etc/libvirt/qemu.conf
  - Disable security: `security_driver = "none"` (uncomment and/or modify if needed)
  - Uncomment `user = "root"`
  - Uncomment `group = "root"`
- Save file and restart libvirtd
  - `service libvirtd restart`

### TODO

Currently doesn't have DHCP4 Proxy, AAA and connection to Signal and OAM networks

![Current Implementation of vBNG](https://github.com/cncf/cnfs/blob/master/comparison/box-by-box-kvm-docker/vBNG/vBNG.png)
eth3 omitted as it is not currently used
