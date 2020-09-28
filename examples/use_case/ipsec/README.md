## Install IPsec Service Chain Example (1 chain of 4 nodes)

This example installs the IPsec service chain example on a kubernetes worker node. All connections are done using Memif interfaces. Connections between 1-2 and 3-4 are direct, while the connection between 2-3 uses IPsec encapsulation and goes through the host vSwitch (VPP).

![Example IPsec service chain](ipsec.png)

### Prerequisites
A Kubernetes deployment with a host vSwitch (VPP) must be deployed prior to installing this example. Guides for setting this up can be found here:
* [Provision HW and deploy CNF Testbed Kubernetes cluster](/docs/Deploy_cnf_testbed_k8s.md)
* [Deploy vSwitch (VPP) in CNF Testbed Kubernetes cluster](/docs/Deploy_vswitch_cnf_testbed.md)

You should have a `kubeconfig` file ready on the machine, as it is used to deploy the example on a worker node.

Helm must be installed prior to installing this example. The steps listed below are based on [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)
```
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

You will also need to configure a packet generator to test the example. Steps for doing this can be found in [Deploy Packet Generator](/docs/Deploy_pktgen_cnf_testbed.md). Be sure to note down the MAC addresses of the ports as mentioned in the section, as these will be needed prior to deploying the example.

**Preparing the K8s worker node**

Before installing this (IPsec) example use case, the vSwitch (VPP) configuration needs to be updated. SSH to the worker node and replace the vSwitch configuration as shown below:
```
$ cp /etc/vpp/templates/ipsec.gate /etc/vpp/setup.gate
```

Once that has been done, restart the vSwitch using the below step (depending on how the vSwitch is deployed):
```
## vSwitch running in host
$ service vpp restart

## vSwitch running in container
$ docker restart vppcontainer
```

### Installing the IPsec service chain example

_Make sure no other example use cases is currently installed - Check using `helm list` and delete using `helm delete <name>` if necessary

Start by modifying the first line in [ipsec/values.yaml](./ipsec/values.yaml) to include the MAC addresses of the packet generator that were collected as part of the prerequisites. Once that is done, install the example by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm install ipsec ./ipsec/
```

### Testing the IPsec service chain example

Follow the steps listed in [Deploy Packet Generator](/docs/Deploy_pktgen_cnf_testbed.md).

The configuration will need to be updated prior to running this example. SSH to the packet generator machine and update `/root/nfvbench_config.cfg` to use only one chain:
```
service_chain_count: 1
```

### Removing the Snake service chain example

To remove this example use case, run the below command:
```
$ helm delete ipsec
```

