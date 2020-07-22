## Install Pipeline Service Chain Example (3 chains of 2 nodes)

This example installs the pipeline service chain example on a kubernetes worker node. All nodes are connected using Memif interfaces, with the chain endpoints connecting to the host vSwitch (VPP) while the intermediate connections are done directly between nodes.

### Prerequisites
A Kubernetes deployment with a host vSwitch (VPP) must be deployed prior to installing this example. A guide to deploying K8s can be found in [Deploy_K8s_CNF_Testbed.md](https://github.com/cncf/cnf-testbed/blob/master/docs/Deploy_K8s_CNF_Testbed.md)

You should have a `kubeconfig` file ready on the machine, as it is used to deploy the example on a worker node.

Helm must be installed prior to installing this example. The steps listed below are based on [https://helm.sh](https://helm.sh/docs/using_helm/#from-script)
```
$ curl -LO https://git.io/get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
$ helm init --service-account tiller

## You might need to run the below if versions are mismatched
  $ helm init --upgrade
  $ helm init --service-account tiller
```

You will also need to configure a packet generator to test the example. Steps for doing this can be found in [Deploy Packet Generator](https://github.com/cncf/cnf-testbed/blob/master/docs/Deploy_K8s_CNF_Testbed.md#deploy-packet-generator). Be sure to note down the MAC addresses of the ports as mentioned in the section, as these will be needed prior to deploying the example

**Preparing the K8s worker node**

The host vSwitch (VPP) configuration must be updated prior to running this example.

On the worker node, start by checking the PCI devices used by VPP:
```
$ grep dev /etc/vpp/startup.conf | grep -v default
## (example, n2.xlarge) dev 0000:1a:00.1 dev 0000:1a:00.3
## (example, m2.xlarge) dev 0000:5e:00.1
## n2.xlarge (Intel) servers have two devices, m2.xlarge (Mellanox) has one device
```

Now replace the configuration file with the one for this example as follows:
```
$ cp /etc/vpp/templates/3c2n-csp.gate /etc/vpp/setup.gate
```

Once the filw has been replaced, open it (`/etc/vpp/setup.gate`) with your favorite editor, and make sure the device names match the PCI devices listed previously. Make sure all instances of the name are updated:
```
## (example, n2.xlarge) TenGigabitEthernet1a/0/1, TenGigabitEthernet1a/0/3
## (example, m2.xlarge) TwentyFiveGigabitEthernet5e/0/1
```

Once that has been done, restart the vSwitch using the below step (depending on how the vSwitch is deployed):
```
## vSwitch running in host
$ service vpp restart

## vSwitch running in container
$ docker restart vppcontainer
```

### Installing the Pipeline service chain example

Start by modifying the first line in `./csp/values.yaml` to include the MAC addresses of the packet generator that were collected as part of the prerequisites. Once that is done, install the example by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm install ./csp/
```

### Testing the Pipeline service chain example

Follow the steps listed in [Run Traffic Benchmark](https://github.com/cncf/cnf-testbed/blob/master/docs/Deploy_K8s_CNF_Testbed.md#run-traffic-benchmark). The packet generator should be configured for 3 chains with this example

