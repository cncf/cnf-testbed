## Install POD using the SRIOV Network Device Plugin on Kubernetes

This example is used to install a POD using the [SRIOV Network Device Plugin](https://github.com/intel/sriov-network-device-plugin).

The POD is assigned a single port using vfio-pci, which is then attached to an instance of VPP running in the container.

### Limitations

The SRIOV Network Device Plugin is intended for providing a limited set of resources to a running container. For this example, the POD is running in privileged mode, which makes all of the available ports using the vfio-pci driver visible inside the container. The POD created through this example will read the list of assigned ports from the environment and configure VPP to only use the allocated resources.

The reason for privileged mode is errors with VPP due to hugepages and access to the vfio-pci kernel module. We are looking into a solution that allows running it unprivileged, but by limiting the configuration to the assigned resources from the SRIOV Device Plugin, the resulting behavior will emulate that of the intended plugin behavior.

### Prerequisites
A Kubernetes deployment with the SRIOV Network Device Plugin installed must be available.

You should have a `kubeconfig` file ready on the machine.

`kubectl` must be installed. The steps included here are taken fron [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux):
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
$ chmod +x kubectl
$ mv kubectl /usr/local/bin/kubectl
```

### Installing the example POD
Install the POD by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ kubectl apply -f sriov-simple-vpp-pod.yaml
```

### Verifying POD deployment
There are a few steps that can be used to verify that the POD deployed correctly:
```
## Start by checking that the POD is running (you might need to way a few seconds after deploying)
$ kubectl get pods

## Once running, enter the container
$ kubectl exec -it sriov-simple-vpp-pod /bin/bash

## Check for an allocated PCI device (NIC port)
$$ env | grep PCIDEVICE
PCIDEVICE_INTEL_COM_VFIO_PORTS=0000:XX:XX.X

## Check that the device has been added to the VPP startup configuration
$$ cat /etc/vpp/startup.conf | grep dev
dev 0000:XX:XX.X

## Finally check that the interface is visible in VPP
$$ vppctl show int
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernetXX/X/X          1     down         9000/0/0/0
local0                            0     down          0/0/0/0
```

The interface in VPP will be in state down, as no `setup.gate` file is provided with the example. You can add a configuration directly through the CLI (`vppcl`), or you can add one as part of the configMap in the example file `sriov-simple-vpp-pod.yaml`, which should be mapped to `/etc/vpp/setup.gate` inside the container.
