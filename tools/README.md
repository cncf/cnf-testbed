**Deploy a K8s cluster to Packet.net**

Set your Packet.net account project & api tokens.
Then run deploy_cluster.sh

```
export PACKET_PROJECT_ID=YOUR_PACKET_PROJECT_ID 
export PACKET_AUTH_TOKEN=YOUR_PACKET_API_KEY
./deploy_cluster.sh
```

After Provisioning has finished, to access the cluster withe kubectl.

```
export KUBECONFIG=$(pwd)/data/kubeconfig
kubectl get nodes
```

To Destroy the cluster run 
```
./destroy_cluster.sh
```

**Deploy Hardware/Infra at Packet.net**

Set your Packet.net account project & api tokens.
Then run hardware_provisioning.sh
```
export PACKET_PROJECT_ID=YOUR_PACKET_PROJECT_ID 
export PACKET_AUTH_TOKEN=YOUR_PACKET_API_KEY
./hardware_provisioning.sh
```

After Provisioning has finished, you will find a nodes.env 
file in the tools/cwd directory. This file can then later be
used as a node list when provisioning a Kubernetes cluster.

Extra/Additional configuration:
The steps above will automatically use the following defaults
found in the hardware_provisioning.sh
```
USE_RESERVED=${USE_RESERVED:-false}
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
PACKET_OS=${PACKET_OS:-ubuntu_16_04}
MASTER_COUNT=${MASTER_COUNT:-1}
MASTER_PLAN=${MASTER_PLAN:-m2.xlarge.x86}
WORKER_COUNT=${WORKER_COUNT:-2}
WORKER_PLAN=${WORKER_PLAN:-m2.xlarge.x86}
```

If you wish to override these defaults you can update/modify the
example configuration in hardware-provisioning.env.example,
then source the new configuration before running the deploy scipt.
```
source ./hardware-provisioning.env.example
./hardware_provisioning.sh
```



