## Install Packet-filtering service chain using NSM and Kubernetes

This example is used to install a packet-filtering service chain using NSM ([Network Service Mesh](https://networkservicemesh.io/)).

The service chain can be seen below:
```
    +--------+
    |        |
    | Kernel |
    | Client +-------+
    |        |       |
    +--------+       |       ----------------+                +---------+
                     +------->               |  10.60.2.0/24  |         |
               10.60.3.0/24  | Packet Filter +----------------> Gateway |
                     +------->               |                |         |
    +--------+       |       +---------------+                +---------+
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

### Installing Packet-filtering example
Install the packet-filtering example by running the below commands from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ kubectl apply -f packet-filtering.yaml -f gateway.yaml -f packet-filter.yaml -f simple-client.yaml -f ucnf-client.yaml
```

### Testing the Packet-filtering example
Once the example has been installed, wait about a minute before running the below command (script). You should see connectivity between both the Kernel and VPP client towards the Gateway
```
$ ./check_packet_filtering.sh
```
