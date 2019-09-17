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

The host vSwitch (VPP) configuration must be updated prior to running this example. For now this can be done using the provided `setup.gate` template.

On the worker node, start out by checking the existing configuration located in `/etc/vpp/setup.gate`. It should contain lines with the interface names, i.e. `TenGigabitEthernetXX/X/X`. Note down the these, and replace the names provided in the example `setup.gate` file with those. Once that is done, replace the content of `/etc/vpp/setup.gate` on the worker node with the content of the example file. Once that has been done, restart the vSwitch using the below step (depending on how the vSwitch is deployed):
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

