# K8s cluster with SRIOV Network Device Plugin

## Install SRIOV Network Device Plugin on an existing Kubernetes deployment

This example is used to install the [SRIOV Network Device Plugin](https://github.com/intel/sriov-network-device-plugin) with a simple configuration. The provided configuration uses a pre-built image (soelvkaer/sriov-device-plugin:latest) similar to what can be created by running `make && make image` from the [source repository](https://github.com/intel/sriov-network-device-plugin). The configuration provided here is also based on examples already provided with the code.

### Prerequisites
A Kubernetes deployment must be avaialble prior to installing the plugin.

You should have a `kubeconfig` file ready on the machine used for installing the plugin.

`kubectl` must be installed. The steps included here are taken fron [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux):
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
$ chmod +x kubectl
$ mv kubectl /usr/local/bin/kubectl
```

Before installing, connect (SSH) to the worker node of the Kubernetes cluster, and stop any instance of VPP running on the node:
```
## If running as a service
$ service vpp stop

## If running as a container
$ docker stop vppcontainer
```

### Installing SRIOV Network Device Plugin
Install the plugin with a simple configuration by running the following command from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ kubectl apply -f configMap.yaml -f sriovdp-daemonset.yaml
```

After installing the plugin, you can verify that there are ports/interfaces available by running the following commands:
```
$ kubectl get nodes
## Copy the name of the node

$ kubectl get node <name of node> -o json | jq '.status.allocatable'
## Output similar to the below should be seen
{
  "cpu": "55",
  "ephemeral-storage": "210725550141",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "20Gi",
  "intel.com/vfio_ports": "2",  <--- Node has two ports
  "memory": "373838964Ki",
  "pods": "110"
}
```
