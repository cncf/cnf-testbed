# Deploy vSwitch (VPP) in CNF Testbed Kubernetes Cluster

This document will show how to set up a CNF Testbed environment. Everything will be deployed on servers hosted by Packet.com.

Before deploying the vSwitch, make sure that a CNF Testbed Kubernetes Cluster has already been deployed. Steps for doing this can be found [here](new_deploy_cnf_testbed_k8s.md). The environment file used for deploying the Kubernetes cluster will be used for deploying the vSwitch as well.

## Prerequisites
Before starting the deployment you will need access to a project on Packet. Note down the **PROJECT_NAME** and **PROJECT_ID**, both
found through the Packet web portal, as these will be used throughout the deployment for provisioning servers and configuring the network. You will also need a personal **PACKET_AUTH_TOKEN**, which is created and found in personal settings under API Keys.

You should also make sure that you have a keypair available for SSH access. You can add your public key to the project on Packet through the web portal, which ensures that you will have passwordless SSH access to all servers used for deploying the CNF Testbed.

## Deploy vSwitch in CNF Testbed Kubernetes Cluster

While no additional configuration is needed, there are a few configuration options that can be modified prior to installing the vSwitch.

By default, if the 'n2.xlarge.x86' instance type is used, vSwitch installation is done using  `cnf-testbed/comparison/ansible/k8s_worker_vswitch_quad_intel.yml`. This file has a few variables that can be changed:
```
vswitch_container: false
## Run the vSwitch (VPP) in a container. By default (false) it runs directly on the host
corelist_workers: 3
## Number of cores to use for workload in the vSwitch
rx_queues: 3
## Number of receive queues per NIC port in the vSwitch
multus_cni: false
## Configure the node for use with SRIOV Network Device Plugin and CNI (examples/workload-infra/multus_sriov)
## Changing this to true disables the vSwitch
```

If using the 'm2.xlarge.x86' instance type, with the PLAYBOOK variable uncommented in the environment file, the installation is done using `cnf-testbed/comparison/ansible/k8s_worker_vswitch_mellanox.yml`, which also has a few configuration options:
```
vswitch_container: false
## Run the vSwitch (VPP) in a container. By default (false) it runs directly on the host
corelist_workers: 3
## Number of cores to use for workload in the vSwitch
rx_queues: 6
## Number of receive queues per NIC port in the vSwitch
```

Once configured, return to the cnf-testbed directory, and install the vSwitch using the Makefile:
```
$ make vswitch load_envs ${PWD}/tools/k8s-example.env
## Use the same environment file as for the cluster
```

Once completed, and if `multus_cni: false`, SSH to the worker node(s) and verify that the vSwitch is running.

If `vswitch_container: false`:
```
$ vppctl show version
```

Else, if `vswitch_container: true`:
```
$ docker exec -it vppcontainer vppctl show version
```

If `multus_cni: true` has been configured, the next steps for installing the SRIOV plugins can be found [here](/examples/workload-infra/multus_sriov).
