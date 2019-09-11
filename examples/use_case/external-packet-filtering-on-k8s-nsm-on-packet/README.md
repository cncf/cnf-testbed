## Install External Packet-filtering service chain using NSM and Kubernetes

This example is used to install a modified version of the packet-filtering service chain using NSM ([Network Service Mesh](https://networkservicemesh.io/)). This version includes an "External" Gateway attached to physical network ports, which allows for connectivity between the clients and a separate server node.

This use-case is best deployed on a Kubernetes worker that has been configured to use a host vSwitch, as this will do additional configuration which is necessary for the external gateway to function correctly. A few steps are listed in the prerequisites section to ensure configuration is correct, but details on some steps, e.g. Packet infrastructure configuration, has been omitted.

The service chain can be seen below:
```
    +--------+
    |        |
    | Kernel |
    | Client +-------+
    |        |       |
    +--------+       |       ----------------+                +---------+              +--------+
                     +------->               |  10.60.2.0/24  | Ext.    | 10.60.1.0/24 | Phys.  |
               10.60.3.0/24  | Packet Filter +----------------> Gateway +--------------> Server |
                     +------->               |                |         |              |        |
    +--------+       |       +---------------+                +---------+              +--------+
    |        |       |
    |  VPP   +-------+
    | Client |
    |        |
    +--------+
```

### Prerequisites
A Kubernetes deployment with NSM installed must be available. For steps to install NSM see this [README.md](https://github.com/cncf/cnf-testbed/blob/wip-new-examples-structure/examples/workload-infra/nsm-k8s/README.md)

You should have a `kubeconfig` file ready on the machine.

`kubectl` must be installed. The steps included here are taken fron [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux):
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
$ chmod +x kubectl
$ mv kubectl /usr/local/bin/kubectl
```

In addition you will need to create a new server to be used as the "Physical Server" endpoint. This README will use the `n2.xlarge` (Intel NIC), but the `m2.xlarge` (Mellanox NIC) or other servers that allow Mixed Networking and assigning VLANs to ports can be utilized. Configure the machine with Mixed Networking through Packet, and assign VLANs to interfaces matching those used in the Kubernetes deployment.

**Additional steps to ensure the node is prepared for the use-case**

If the Kubernetes deployment includes a host vSwitch (VPP), this must be disabled on the worker node prior to deploying this use-case. This is done by logging into the worker node, and running one of the following commands depending on the vSwitch deployment method (directly on in container):
```
## vSwitch running in host
$ service vpp stop

## vSwitch running in container
$ docker stop vppcontainer
```

On the worker node, ensure that the kernel/GRUB is configured correctly. Check by using `$ cat /proc/cmdline` and make sure that `intel_iommu=on iommu=pt` are listed. If this is not the case, update the settings (modify `/etc/default/grub` and run `update-grub`) and reboot the machine. Once rebooted, go through the following checklist:
* Make sure the vSwitch is stopped
* Make sure interfaces `eno2` and `eno3` are not part of `bond0`
  - Provided gateway.yaml expects the PCI addresses of these to be `0000:19:00.1` and `0000:19:00.2`
  - Modify as needed
* Make sure that the above ports are configured to use the `vfio-pci` driver
  - You can use the provided `dpdk-devbind.py` script
  - (Check current driver) `./dpdk-devbind.py -s`
  - (Bind to vfio-pci if needed) `./dpdk-devbind -b vfio-pci 0000:19:00.1 0000:19:00.2`
  - If `vfio-pci` is not avaialble, install the `dpdk` package on the node (`apt-get install dpdk`)

At this point you should be ready to install the Packet-filtering example. This has only been tested on a Kubernetes worker where a host vSwitch was already installed - If this is not the case in your deployment there might be additional steps needed to configure the ports with the `vfio-pci` driver, and to configure the ports to use the same VLANs as the "Physical Server" mentioned above.

### Installing Packet-filtering example
Install the packet-filtering example by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ kubectl apply -f packet-filtering.yaml -f gateway.yaml -f packet-filter.yaml -f simple-client.yaml -f ucnf-client.yaml
```

On the other physical server ("endpoint") Find the interface that is connected to the same VLAN as as `0000:19:00.2` on the Kubernetes worker. Make sure that this interface is removed from the default bond, `$ echo "-enoX" > /sys/class/net/bond0/bonding/slaves`.
Configure the interface with an IP address in the `10.60.1.0/24` subnet, and add a route towards the other service chain endpoints:
```
## Replace "X's" as needed
$ ifconfig enoX 10.60.1.XX netmask 255.255.255.0
$ ip route add 10.60.3.0/24 via 10.60.1.50 dev enoX
```

Ensure that the configured interface is up - You can run `$ ifconfig enoX up` (replace "X") to do this.

### Testing the Packet-filtering example
Once the example has been installed, wait about a minute before running the below command (script). You should see connectivity between both the Kernel and VPP client towards the external Gateway (not testing external connectivity)
```
$ ./check_packet_filtering.sh
```

The above script currently doesn't support testing towards the "external" physical server. To test this, note down the IP of the physical server and run the following:
```
$ ./check_ext_packet_filtering.sh <IP of "external" interface>
```

