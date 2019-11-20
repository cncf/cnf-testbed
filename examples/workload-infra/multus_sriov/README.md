## Multus, SRIOV CNI and SRIOV Network Device Plugin on K8s

This infrastructure example will install [Multus](https://github.com/intel/multus-cni), [SRIOV CNI](https://github.com/intel/sriov-cni) and [SRIOV Network Device Plugin](https://github.com/intel/sriov-network-device-plugin) on an existing Kubernetes deployment.

Prior to deploying the infrastructure, you will need to deploy a Kubernetes cluster with a specific flag set, and once deployed verify that SRIOV devices are available on the worker node. Steps to do this can be found in the _Prerequisites_ section.

### Prerequisites
You will need to deploy a specific Kubernetes cluster for this infrastructure example to work. The cluster must be deployed on `n2.xlarge.x86` (Intel NIC) server(s). First you will need to modify [comparison/ansible/k8s_worker_vswitch_quad_intel.yml](https://github.com/cncf/cnf-testbed/blob/master/comparison/ansible/k8s_worker_vswitch_quad_intel.yml) to enable support for Multus:
```
multus_cni: true
```

Once this has been done, follow the steps for [deploying a kubernetes cluster](https://github.com/cncf/cnf-testbed/blob/master/docs/Deploy_K8s_CNF_Testbed.md#deploy-k8s-cluster)

Make sure to have the kubeconfig file (found in `tools/data`) available for future use.

SSH to the Kubernetes worker node, and check if the additional SRIOV VFs have been created:
```
$$ lspci | grep "Ethernet Virtual"
XX:XX.X Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 01)
(...)
XX:XX.X Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 01)
```

If the list is empty, you will need to do an additional step to enable SRIOV on the NIC.

**Enable SRIOV on the NIC**

Conenct to the out-of-band console (information can be found on the Packet web portal) and reboot the Kubernetes worker node. During reboot, enter the BIOS configuration using the information shown in the console (you will have to enter a few inputs, e.g. <ESC> + <2> to enter <F2> during the boot process). Once you are in the BIOS, change the NIC virtualization mode at the path shown below: 
```
System BIOS >> Device Settings >> Ethernet Converged Network Adapter X710 >> Device Level Configuration >> Virtualization Mode = SR-IOV
```

Once done, save the changes and reboot the machine again. Once up, verify that the VFs are created using `lspci` (see above).

### Installing Multus, SRIOV CNI and SRIOV Network Device Plugin on K8s
Once the Kubernetes cluster has been created and VFs are avaialble on the worker, you are ready to install this infrastructure example.

Start by ensuring that the KUBECONFIG environment variable is set
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
```

Then, from this directory run the installation script:
```
$ ./installer.sh
```

Once the script completes, wait an addition 30-60 seconds as services on the worker are restarted, and check the status of the node:
```
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                   READY   STATUS    RESTARTS   AGE
kube-system   heapster-xxxxxxxxxx-xxxxx                              2/2     Running   2          1h
kube-system   kube-dns-xxxxxxxxxx-xxxxx                              3/3     Running   3          1h
kube-system   kube-dns-autoscaler-xxxxxxxxxx-xxxxx                   1/1     Running   1          1h
kube-system   kube-multus-ds-amd64-xxxxx                             1/1     Running   0          1h
kube-system   kube-proxy-xxxx-worker-1.xxxx.packet.local             1/1     Running   1          1h
kube-system   kube-sriov-device-plugin-amd64-xxxxx                   1/1     Running   0          1h

$ kubectl get node $(kubectl get node | grep worker | awk '{print $1}') -o json | jq '.status.allocatable'
{
  "cpu": "55",
  "ephemeral-storage": "210667024855",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "20Gi",
  "intel.com/sriov_ports_left": "4",
  "intel.com/sriov_ports_right": "4",
  "intel.com/vfio_ports_left": "4",
  "intel.com/vfio_ports_right": "4",
  "memory": "373904712Ki",
  "pods": "110"
}
```

All pods and individual parts should be running, and the node details should contain entries for SRIOV and VFIO ports (left and right) as shown above.

At this point Multus, SRIOV CNI and the SRIOV Network Device Plugin has been deployed and is ready to use.

### Deleting Multus, SRIOV CNI and SRIOV Network Device Plugin on K8s

You can delete the deployment using the installer script found in this directory:
```
$ ./installer.sh del
```

Do note that the Kubernetes cluster created for this infrastructure requires Multus to function properly. You can install it again by using the installer script and following the steps included in this document.
