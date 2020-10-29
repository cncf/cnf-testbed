# Reproducing the CI Environment

If you want to deploy the CNF-Testbed in the same way that our CI job does, you
can do that by using the Makefile and following the steps below.

## Pre-requisites:
Set your [Equinix Metal] project name, id & api tokens. These can be found through the [Console].
```
export PACKET_AUTH_TOKEN=YOUR_EQUINIX_METAL_AUTH_TOKEN
export PROJECT_ID=YOUR_EQUINIX_METAL_PROJECT_ID
export PACKET_PROJECT_NAME='YOUR EQUINIX METAL PROJECT NAME'
```

Then change dir to the top level of the CNF-Testbed repo and build the deps.
```
cd ..
make deps 
```
## Deploying a Kubernetes cluster using the Makefile / CI tools:
Run the below make commands and Make will re-create the K8s setup used in our CI environment.
```
make hw_k8s
make k8s
```

## Deploying a vSwitch using the Makefile / CI tools:
Run the below make commands and Make will re-create the vSwitch setup used in our CI environment.
```
make vswitch
```

## Deploying the GoGTP Multi-node network using the Makefile:
Needed to pre-configure the network prior to running the [GoGTP Multi-node use-case](https://github.com/cncf/cnf-testbed/tree/go-gtp/examples/use_case/gogtp-k8s/k8s_multi_node).

Run the below commands and Make will configure the network connection between worker nodes:
```
make gogtp_multi [load_envs <path/to/env/file>]
```

Information about the environment (configuration) file can be found in the use-case readme referenced above.

## Deploying a Packet Generator using the Makefile / CI tools:
Run the below make commands and Make will re-create the packet generator setup used in our CI environment.
```
make hw_pktgen
make pktgen
```

## Deploying the Snake use case using the Makefile / CI tools:
```
make snake
```

## Add CPU isolation to nodes in an existing Kubernetes cluster:
This is necessary prior to deploying the [cpu-manager](../examples/workload-infra/cpu-manager) workload-infra example.
To reach the correct worker nodes you must reference the environment file (load_envs) that was also used to provision HW and deploy Kubernetes.
```
make isolcpus [load_envs <path/to/env/file>]
```

## Extra/Additional configuration when using Make:
The steps above will automatically use the defaults for bringing up our CI environment.
If you want to use Make to bring up a custom environment, this can be done by running 
make and passing the load_envs argument.

To run say, "make hw_k8s" with a custom environment/configuration, you could do something like:

```make hw_k8s load_envs ./tools/hardware-provisioning.env.example```


# Deploy the CNF-Testbed using the CLI tools directly.

## Deploy Hardware/Infra at Equinix Metal

Set your [Equinix Metal] ([Console]) account project & api tokens.
Then run hardware_provisioning.sh
```
export PACKET_PROJECT_ID=YOUR_EQUINIX_METAL_PROJECT_ID
export PACKET_AUTH_TOKEN=YOUR_EQUINIX_METAL_API_KEY
./hardware_provisioning.sh
```

After Provisioning has finished, you will find a nodes.env 
file in the tools/data/cnftestbed/ directory. This file can then later be
used as a node list when provisioning a Kubernetes cluster.

Extra/Additional configuration:
The steps above will automatically use the following defaults
found in hardware_provisioning.sh
```
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
USE_RESERVED=${USE_RESERVED:-false}
STATE_FILE=${STATE_FILE:-$(pwd)/data/$DEPLOY_NAME/terraform.tfstate}
NODE_FILE=${NODE_FILE:-$(pwd)/data/$DEPLOY_NAME/kubernetes.env}

NODE_GROUP_ONE_NAME=${NODE_GROUP_ONE_NAME:-$DEPLOY_NAME-master}
NODE_GROUP_TWO_NAME=${NODE_GROUP_TWO_NAME:-$DEPLOY_NAME-worker}
NODE_GROUP_ONE_COUNT=${NODE_GROUP_ONE_COUNT:-1}
NODE_GROUP_TWO_COUNT=${NODE_GROUP_TWO_COUNT:-1}
FACILITY=${PACKET_FACILITY:-sjc1}
NODE_GROUP_ONE_DEVICE_PLAN=${NODE_GROUP_ONE_DEVICE_PLAN:-m2.xlarge.x86}
NODE_GROUP_TWO_DEVICE_PLAN=${NODE_GROUP_TWO_DEVICE_PLAN:-n2.xlarge.x86}
OPERATING_SYSTEM=${OPERATING_SYSTEM:-ubuntu_16_04}
```

If you wish to override these defaults you can update/modify the
example configuration in hardware-provisioning.env.example,
then source the new configuration before running the deploy scipt.
```
source ./hardware-provisioning.env.example
./hardware_provisioning.sh
```


## Provison Kubernetes/Infra

First create a cluster config by running kubernetes_provisioning.sh generate_config 
```
./kubernetes_provisioning.sh generate_config
```
After generate_config has finished running you will find a cluster configuration file under tools/data/cnftestbed/cluster.yml

Lastly start the cluster provisioning with kubernetes_provisioning provision
```
./kubernetes_provisioning.sh provision
```

After Provisioning has finished, you will find a kubeconfig 
file under the path tools/data/cnftestbed/mycluster/artifacts/admin.conf. 
This file can be used in the next stage to provide a list of worker nodes
when provisioning the VPP vSwitch.

Extra/Additional configuration:
The steps above will automatically use the following defaults
found in kubernetes_provisioning.sh
```
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
RELEASE_TYPE=${RELEASE_TYPE:-stable}
HOSTS_FILE=${HOSTS_FILE:-$(pwd)/data/$DEPLOY_NAME/kubernetes.env}
```

If you wish to override these defaults you can update/modify the
example configuration in kubernetes-provisioning.env.example,
then source the new configuration before running the generate config & provisioning scipts.
```
source ./kubernetes-provisioning.env.example
./kubernetes_provisioning.sh generate_config
./kubernetes_provisioning.sh provision
```

## Provision the VPP vSwitch

Set your [Equinix Metal] ([Console]) project name & api tokens.
Then run kubernetes_provisioning.sh vswitch
```
export PACKET_PROJECT_NAME='YOUR EQUINIX METAL PROJECT NAME'
export PACKET_AUTH_TOKEN=YOUR_EQUINIX_METAL_API_KEY
./kubernetes_provisioning.sh vswitch
```

After Provisioning has finished, you should have a VPP vSwitch 
on all worker nodes in your cluster.

Extra/Additional configuration:
The steps above will automatically use the following defaults
found in kubernetes_provisioning.sh
```
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
PROJECT_ROOT=${PROJECT_ROOT:-$(cd ../ ; pwd -P)}
FACILITY=${FACILITY:-sjc1}
VLAN_SEGMENT=${VLAN_SEGMENT:-$DEPLOY_NAME}
PLAYBOOK=${PLAYBOOK:-k8s_worker_vswitch_quad_intel.yml}
KUBECONFIG=${KUBECONFIG:-$(pwd)/data/$DEPLOY_NAME/mycluster/artifacts/admin.conf}
```

If you wish to override these defaults you can update/modify the
example configuration in vswitch-provisioning.env.example,
then source the new configuration before running the generate config & provisioning scipts.
```
source ./vswitch-provisioning.env.example
./kubernetes_provisioning.sh vswitch
```

- [Equinix Metal]: https://metal.equinix.com/ "Equinix Metal"
- [Console]: http://console.equinix.com/ "Console"
