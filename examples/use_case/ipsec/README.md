## Install IPsec Service Chain Example (1 chain of 4 nodes)

This example installs the IPsec service chain example on a kubernetes worker node. All connections are done using Memif interfaces. Connections between 1-2 and 3-4 are direct, while the connection between 2-3 goes through the host vSwitch (VPP).

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
## (example, n2.xlarge) dev 0000:1a:00.1 dev 0000:1a:00.2
## (example, m2.xlarge) dev 0000:5e:00.1
## n2.xlarge (Intel) servers have two devices, m2.xlarge (Mellanox) has one device
```

Now replace the configuration file with the one for this example as follows:
```
$ cp /etc/vpp/templates/ipsec.gate /etc/vpp/setup.gate
```

Once the filw has been replaced, open it (`/etc/vpp/setup.gate`) with your favorite editor, and make sure the device names match the PCI devices listed previously. Make sure all instances of the name are updated:
```
## (example, n2.xlarge) TenGigabitEthernet1a/0/1, TenGigabitEthernet1a/0/2
## (example, m2.xlarge) TwentyFiveGigabitEthernet5e/0/1
```

Once that has been done, restart the vSwitch using the below step (depending on how the vSwitch is deployed):
```
## vSwitch running in host
$ service vpp restart

## vSwitch running in container
$ docker restart vppcontainer
```

### Installing the IPsec service chain example

Start by modifying the first line in `./ipsec/values.yaml` to include the MAC addresses of the packet generator that were collected as part of the prerequisites. Once that is done, install the example by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm install ./ipsec/
```

### Testing the IPsec service chain example

Follow the steps listed in [Run Traffic Benchmark](https://github.com/cncf/cnf-testbed/blob/master/docs/Deploy_K8s_CNF_Testbed.md#run-traffic-benchmark). The packet generator should be configured for 1 chain with this example

