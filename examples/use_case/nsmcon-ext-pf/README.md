## Install NSMCon External Packet-filtering service chain using NSM and Kubernetes
This use-case is a variation of the [External Packet-filtering](https://github.com/cncf/cnf-testbed/tree/master/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet) example that is already available in the testbed. As with the existing use-case, this one also uses [NSM](https://networkservicemesh.io/) for configuring the the containers and the connections between them, with the exception of the external interfaces that must be configured manually.

This variation has two external gateways, each connected to an external interfaces on a different server. Both the Kernel ("Simple") and VPP Client can reach both external interfaces by pinging their IP addresses.

This use-case is best deployed on a Kubernetes worker that has been configured to use a host vSwitch, as this will do additional configuration which is necessary for the external gateways to function correctly. A few steps are listed in the prerequisites section to ensure configuration is correct, but details on some steps, e.g. Packet infrastructure configuration, has been omitted.

The service chain can be seen below:
```
                           Kubernetes Worker Node                                     External Server
+--------------------------------------------------------------------------+        +------------------+
|                                                                          |        |                  |
   +--------+
   |        |                                                 +---------+              +------------+
   | Kernel |                                    10.60.3.0/24 | Ext.    | 10.60.1.0/24 | Ext. IF    |
   | Client +-------+                           +-------------> Gateway +--------------+ 10.60.1.10 |
   |        |       |                           |             |         |              |            |
   +--------+       |       +---------------+   |             +---------+              +------------+
                    +------->               +---+
              10.60.4.0/24  | Packet Filter |
                    +------->               +---+
   +--------+       |       +---------------+   |             +---------+              +------------+
   |        |       |                           |             | Ext.    |              | Ext. IF    |
   |  VPP   +-------+                           +-------------> Gateway +--------------+ 10.60.0.10 |
   | Client |                                    10.60.2.0/24 |         | 10.60.0.0/24 |            |
   |        |                                                 +---------+              +------------+
   +--------+
```

### Prerequisites
A Kubernetes deployment with NSM installed must be available. For steps to install NSM see this [README.md](https://github.com/cncf/cnf-testbed/blob/wip-new-examples-structure/examples/workload-infra/nsm-k8s/README.md)

The worker node(s) in the Kubernetes cluster must be `n2.xlarge.x86` (Intel NIC) servers from [Packet](https://www.packet.com/).

You should have a `kubeconfig` file ready on the machine.

`kubectl` must be installed. The steps included here are taken fron [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux):
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
$ chmod +x kubectl
$ mv kubectl /usr/local/bin/kubectl
```

Helm must also be installed prior to installing this example. The steps listed below are based on [helm.sh](https://helm.sh/docs/using_helm/#from-script)
```
$ curl -LO https://git.io/get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
$ helm init --service-account tiller

## You might need to run the below if versions are mismatched
  $ helm init --upgrade
```

If you wish to test the service chain you will need an additional server configured with the same VLANs as the Kubernetes worker node(s). For this example an additional `n2.xlarge.x86` server is used. It is possible to use a different server, but you will need to use different steps to configure it for testing.

Additional steps to ensure the node is prepared for the use-case

If the Kubernetes deployment includes a host vSwitch (VPP), this must be disabled on the worker node prior to deploying this use-case. This is done by logging into the worker node, and running one of the following commands depending on the vSwitch deployment method (directly on in container):
```
## vSwitch running in host
$ service vpp stop

## vSwitch running in container
$ docker stop vppcontainer
```

While on the worker node, run the following command to get the two PCI devide IDs that will be used when installing the example:
```
$ cat /etc/vpp/startup.conf | grep dev | grep -v default
(example) dev 0000:1a:00.1 dev 0000:1a:00.3
```

### Installing the NSMCon External Packet-filtering Example
Install the example by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig

## Update the values.yaml file with the PCI device IDs found earlier
$ (example) cat helm/nsmconpf/values.yaml
extport:
  left: "0000:1a:00.1"
  right:  "0000:1a:00.3"

## Install the example
$ helm install --name=nsmconpf helm/nsmconpf/
```

### Testing the NSMCon External Packet-filtering Example
Once the example has been installed, connect to the additional server that has been created for testing the example. Make sure that the machine has been configured in "Mixed/Hybrid" network mode, with VLANs added to two of the ports (e.g. eth1 and eth2).

On the machine, check the existing bond0 and remove the second interface if needed
```
$ cat /sys/class/net/bond0/bonding/slaves
## (example) eno1 eno3
$ (example) echo "-eno3" > /sys/class/net/bond0/bonding/slaves
```

A good way to check how the ports are mapped is to use lshw as follows:
```
$ apt-get install lshw
$ lshw -c network -businfo
Bus info          Device     Class          Description
=======================================================
pci@0000:1a:00.0  eno1       network        Ethernet Controller X710 for 10GbE SFP+
pci@0000:1a:00.1  eno2       network        Ethernet Controller X710 for 10GbE SFP+
pci@0000:1a:00.2  eno3       network        Ethernet Controller X710 for 10GbE SFP+
pci@0000:1a:00.3  eno4       network        Ethernet Controller X710 for 10GbE SFP+
                  bond0      network        Ethernet interface
```

If the VLANs were added to eth1 and eth2 in the Packet web portal, this would correspond to eno2 and eno3 in the table above. To use the example we need to isolate the interfaces, which will be done through two network namespaces, "left" and "right":

```
$ ip netns add left
$ ip netns add right
$ ip link set eno2 netns left
$ ip link set eno3 netns right
$ ip netns exec left ifconfig eno2 10.60.1.10/24
$ ip netns exec right ifconfig eno3 10.60.0.10/24
$ ip netns exec left ip route add 10.60.4.0/24 via 10.60.1.50 dev eno2
$ ip netns exec right ip route add 10.60.4.0/24 via 10.60.0.50 dev eno3
```

At this point you can return to the machine you used for installing the example. Assuming the environment variable `KUBECONFIG` is still set, you can test connectivity from the two clients towards the two external interfaces using the below script:
```
$ ./Kubecon_check_connectivity.sh
```

The script will run pings from both clients to both external interfaces, and if everything has been configured correctly you should see connectivity in all four cases.

### Deleting the NSMCon External Packet-filtering Example
To delete the service chain example, do the following:

```
$ helm delete --purge nsmconpf
$ kubectl delete -f helm/nsmconpf/templates/deployment.yaml
```
The extra step using kubectl is needed as the deployments are using Helm "hooks" to ensure correct ordering. As a consequence, the deployments will not be managed by Helm at the time of deletion, requiring an additional step to remove them.
