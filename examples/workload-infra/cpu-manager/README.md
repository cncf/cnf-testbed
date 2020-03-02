## Install CPU Manager for Kubernetes (CMK) in CNF Testbed
This workload-infra example deploys [CPU Manager for Kubernetes (CMK)](https://github.com/intel/CPU-Manager-for-Kubernetes) to an exsiting CNF Testbed worker node. 

### Prerequisites
A kubernetes cluster with CPU isolation must be available prior to running this example. Steps for configuring this can be found [here](/tools/README.md).

The env variable KUBECONFIG must be specified, to allow the use of `kubectl` towards the cluster
```
## Set the environment variable
$ export KUBECONFIG=/path/to/kubeconfig

## Test connectivity towards cluster
$ kubectl get nodes
```

### Changing configuration
The default configuration provided here will work with a single `n2.xlarge.x86` (Packet.com) worker node. If you have a different server (CPUs) or more nodes, it is possible to modify the configuration to support this. You can change the configuration by modifying the arguments given in the line starting with `/cmk/cmk.py cluster-init` in the [cmk-cluster-init-pod.yaml](cpu-manager/cmk-cluster-init-pod.yaml) file found in this directory.

More details about the configuration can be found [here](https://github.com/intel/CPU-Manager-for-Kubernetes#usage-summary). Be aware that changes can cause the deployment to fail, or result in unexpected behavior.


### Installing (and removing) CMK
CMK can be installed and (partially) removed using the provided [installer.sh](cpu-manager/installer.sh) script:
```
$ installer.sh [del]
```

After running the installer, the deployment will likely take a few minutes. For a single node (default) installation, you can verify that the installation is successful using the below command:
```
$ kubectl get pods -n cmk-namespace
NAME                                      READY   STATUS      RESTARTS   AGE 
cmk-cluster-init-pod                      0/1     Completed   0          86m
cmk-init-install-discover-pod-node1       0/2     Completed   0          86m
cmk-reconcile-nodereport-ds-node1-xxxxx   2/2     Running     0          85m
cmk-webhook-deployment-xxxxxxxxxx-yyyyy   1/1     Running     0          85m
```

The `init` and `discover` pods should be in completed state, while `reconcile` and `webhook` should be in running state.

While the installer script supports removing the CMK parts installed and maintained through Kubernetes, parts of the installation on the host will remain on the target servers. Details on doing this is not included here, but can be found on the CMK Github pages [here](https://github.com/intel/CPU-Manager-for-Kubernetes/blob/master/docs/operator.md#troubleshooting-and-recovery) and [here](https://github.com/intel/CPU-Manager-for-Kubernetes/blob/master/resources/pods/cmk-uninstall-pod.yaml)
