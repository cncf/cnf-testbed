## Install GW-Routers service chain using NSM and Kubernetes

This example is used to install a Gateway and router service chain using NSM ([Network Service Mesh](https://networkservicemesh.io/)).
The service chain can be seen below:
```
    External Server                        Kubernetes Worker Node           
  +------------------+          +------------------------------------------+
  |                  |          |                                          |
     +------------+                +---------+                +---------+   
     |            |                |         |                |         |   
     | Ext. IF    |  10.60.0.0/24  | Gateway |  10.60.1.0/24  | Router  |   
     | 10.60.0.10 +----------------+ Left    +----------------+ Left    |   
     |            |                |         |                |         |   
     +------------+                +---------+                +----+----+   
                                                                   |        
                                                     10.60.2.0/24  |        
                                                                   |        
     +------------+                +---------+                +----+----+   
     |            |                |         |                |         |   
     | Ext. IF    |  10.60.4.0/24  | Gateway |  10.60.3.0/24  | Router  |   
     | 10.60.4.10 +----------------+ Right   +----------------+ Right   |   
     |            |                |         |                |         |   
     +------------+                +---------+                +---------+   
                                                                           
```

### Prerequisites
A Kubernetes deployment with NSM installed must be available. For steps to install NSM see this [README.md](https://github.com/cncf/cnf-testbed/blob/wip-new-examples-structure/examples/workload-infra/nsm-k8s/README.md)

The worker node(s) in the Kubernetes cluster must be `n2.xlarge.x86` (Intel NIC) servers from (Packet)[https://www.packet.com/].

You should have a `kubeconfig` file ready on the machine.

`kubectl` must be installed. The steps included here are taken fron [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux):
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
$ chmod +x kubectl
$ mv kubectl /usr/local/bin/kubectl
```

Helm must also be installed prior to installing this example. The steps listed below are based on [https://helm.sh](https://helm.sh/docs/using_helm/#from-script)
```
$ curl -LO https://git.io/get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
$ helm init --service-account tiller

## You might need to run the below if versions are mismatched
  $ helm init --upgrade
```

If you wish to test the service chain you will need an additional server configured with the same VLANs as the Kubernetes worker node(s). For this example an additional `n2.xlarge.x86` server is used. It is possible to use a different server, but you will need to use different steps to configure it for testing.


### Installing the GW-Routers example
Install the Gateway and router example by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm install --name=gwr helm/gwr/ 
```

### Testing the GW-Routers example
Once the example has been installed, connect to the additional server that has been created for testing the example. Make sure that the machine has been configured in "Mixed/Hybrid" network mode, with VLANs added to two of the ports (e.g. eth1 and eth2).

On the machine, check the existing bond0 and remove the second interface if needed
```
$ cat /sys/class/net/bond0/bonding/slaves
## (example) eno1 eno3
$ (example) echo "-eno3" > /sys/class/net/bond0/bonding/slaves
```

A good way to check how the ports are mapped is to use `lshw` as follows:
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
$ ip netns exec left ifconfig eno2 10.60.0.10/24
$ ip netns exec right ifconfig eno3 10.60.4.10/24
$ ip netns exec left ip route add 10.60.4.0/24 via 10.60.0.50 dev eno2
$ ip netns exec right ip route add 10.60.0.0/24 via 10.60.4.50 dev eno3
```

At this point you should be able to ping between the interfaces. To get a better view of what is happening, the below steps also include running tcpdump on the opposite side of the service chain, which will require two terminal windows:

```
## Left to right
$ (window 1) ip netns exec left ping 10.60.4.10
$ (window 2) ip netns exec right tcpdump -i eno3

## Right to left
$ (window 1) ip netns exec right ping 10.60.0.10
$ (window 2) ip netns exec left tcpdump -i eno2
```

You should see successful pings in both directions, which verifies the connectivity through the service chain.

### Deleting the GW-Routers example
To delete the GW-Routers service chain example, do the following:
```
$ helm delete --purge gwr
$ kubectl delete -f helm/gwr/templates/deployment.yaml
```

The extra step using `kubectl` is needed as the deployments are using Helm "hooks" to ensure correct ordering. As a consequence, the deployments will not be managed by Helm at the time of deletion, requiring an additional step to remove them.
