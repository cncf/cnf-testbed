**Deploy Hardware/Infra at Packet.net**

Set your Packet.net account project & api tokens.
Then run hardware_provisioning.sh
```
export PACKET_PROJECT_ID=YOUR_PACKET_PROJECT_ID 
export PACKET_AUTH_TOKEN=YOUR_PACKET_API_KEY
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
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
PACKET_OS=${PACKET_OS:-ubuntu_16_04}
MASTER_COUNT=${MASTER_COUNT:-1}
MASTER_PLAN=${MASTER_PLAN:-m2.xlarge.x86}
WORKER_COUNT=${WORKER_COUNT:-1}
WORKER_PLAN=${WORKER_PLAN:-n2.xlarge.x86}
```

If you wish to override these defaults you can update/modify the
example configuration in hardware-provisioning.env.example,
then source the new configuration before running the deploy scipt.
```
source ./hardware-provisioning.env.example
./hardware_provisioning.sh
```


**Provison Kubernetes/Infra**

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
HOSTS_FILE=${HOSTS_FILE:-$(pwd)/data/$DEPLOY_NAME/nodes.env}
```

If you wish to override these defaults you can update/modify the
example configuration in kubernetes-provisioning.env.example,
then source the new configuration before running the generate config & provisioning scipts.
```
source ./kubernetes-provisioning.env.example
./kubernetes_provisioning.sh generate_config
./kubernetes_provisioning.sh provision
```

**Provision the VPP vSwitch**

Set your Packet.net project name & api tokens.
Then run kubernetes_provisioning.sh vswitch
```
export PACKET_PROJECT_NAME='YOUR PACKET PROJECT NAME' 
export PACKET_AUTH_TOKEN=YOUR_PACKET_API_KEY
./kubernetes_provisioning.sh vswitch
```

After Provisioning has finished, you should have a VPP vSwitch 
on all worker nodes in your cluster.

Extra/Additional configuration:
The steps above will automatically use the following defaults
found in kubernetes_provisioning.sh
```
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
VLAN_SEGMENT=${VLAN_SEGMENT:-$DEPLOY_NAME}
PLAYBOOK=${PLAYBOOK:-k8s_worker_vswitch_quad_intel.yml}
KUBECONFIG=${KUBECONFIG:-$(pwd)/data/$DEPLOY_NAME/admin.conf}
```

If you wish to override these defaults you can update/modify the
example configuration in vswitch-provisioning.env.example,
then source the new configuration before running the generate config & provisioning scipts.
```
source ./vswitch-provisioning.env.example
./kubernetes_provisioning.sh vswitch
```
