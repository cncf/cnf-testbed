## Example pod utilizing Multus, SRIOV CNI and SRIOV Network Device Plugin on K8s

This example use-case will deploy a pod with multiple external network connections, showcasing [Multus](https://github.com/intel/multus-cni), [SRIOV CNI](https://github.com/intel/sriov-cni) and [SRIOV Network Device Plugin](https://github.com/intel/sriov-network-device-plugin).

The use-case itself has limited functionality, only providing the requested interfaces in the container. The interfaces are however configured with IPv4 subnets, and should be reachable from external endpoints.

```
   +-------------------------------------------+                              
   |                 Multus-gw                 |                                                            
   |       +---------------------------+       |                              
   |       |            VPP            |       |                              
   |       |  +---+ +---+ +---+ +---+  |       |                              
   |  Eth  |  |   | |   | |   | |   |  |  Eth  |                              
   +---|---+--+-|-+-+-|-+-+-|-+-+-|-+--+---|---+                              
       |        |     |     |     |        |                                  
       |        |     |     |     |        |                                  
   +---|--------|-----|-+ +-|-----|--------|---+                                                           
   |     NIC Port 2     | |     NIC Port 3     |                              
   +--------------------+ +--------------------+ 
```

### Prerequisites
This use-case requires a modified Kubernetes cluster, which supports the use of Multus to manage interfaces added to pods. The steps and tools to create this cluster and add the necessary infrastructure tools can be found in [examples/workload-infra/multus_sriov](https://github.com/cncf/cnf-testbed/blob/master/examples/workload-infra/multus_sriov/README.md).

You will also need a `kubeconfig` file pointing to the Kubernetes cluster.

### Installing the example pod
Start by setting the KUBECONFIG environment variable
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
```

Deploy the pod using `kubectl`:
```
$ kubectl apply -f multus-gw.yaml
```

After the initial deploy, wait a few seconds as the image needs to download the pod needs to configure. Verify that the pod is running using:
```
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
multus-gw-xxxxxxxxxx-xxxxx   1/1     Running   0          60s
```

You can now enter the pod and check that the interfaces are available:
```
$ kubectl exec -it $(kubectl get pods | grep multus-gw | awk '{print $1}') /bin/bash

$$ ip a
(...)
8: net1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether (...) brd ff:ff:ff:ff:ff:ff
    inet 10.61.16.4/24 brd 10.61.16.255 scope global net1
       valid_lft forever preferred_lft forever
11: net2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether (...) brd ff:ff:ff:ff:ff:ff
    inet 10.61.0.4/24 brd 10.61.0.255 scope global net2
       valid_lft forever preferred_lft forever

$$ vppctl show int addr
VirtualFunctionEthernetXX/X/X (up):
  L3 10.60.17.15/24
VirtualFunctionEthernetXX/X/X (up):
  L3 10.60.16.15/24
VirtualFunctionEthernetXX/X/X (up):
  L3 10.60.0.15/24
VirtualFunctionEthernetXX/X/X (up):
  L3 10.60.1.15/24
```

### Deleting the example pod
The pod can be deleted using `kubectl`:
```
$ kubectl delete -f multus-gw.yaml
```

