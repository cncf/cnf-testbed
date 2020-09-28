# Deploy CNF Testbed Packet Generator

This document will show how to set up a packet generator for CNF Testbed. Everything will be deployed on servers hosted by [Packet.com](https://www.packet.com/).

The packet generator can be used to verify and benchmark service chains deployed in a CNF Testbed Kubernetes cluster.

## Prerequisites
Before starting the deployment you will need access to a project on Packet. Note down the **PROJECT_NAME** and **PROJECT_ID**, both 
found through the Packet web portal, as these will be used throughout the deployment for provisioning servers and configuring the network. You will also need a personal **PACKET_AUTH_TOKEN**, which is created and found in personal settings under API Keys.

You should also make sure that you have a keypair available for SSH access. You can add your public key to the project on Packet through the web portal, which ensures that you will have passwordless SSH access to all servers used for deploying the CNF Testbed.

## Prepare workstation / jump server
The steps for setting up a workstation can be found [here](/docs/Deploy_cnf_testbed_k8s.md#prepare-workstation--jump-server)

## Deploy CNF Testbed Packet Generator
Start by going to the `tools/` directory. Copy or edit the [pktgen-example.env](/tools/pktgen-example.env) file (for this guide the filename pktgen-example.env is used). The default content of the file is described below.

```
##################################### 
#### Packet.com Project Settings ####
#####################################
export PACKET_AUTH_TOKEN=your-auth-token
export PACKET_PROJECT_ID=your-project-id
export PACKET_PROJECT_NAME="your-project-name"
## These three values are the ones collected as part of the prerequisites earlier.

########################################
#### Packet.com Server Provisioning ####
######################################## 
export DEPLOY_NAME=cnftestbed
## Prefix to use for server hostname and VLANs
## Ideally reuse the same DEPLOY_NAME as for the Kubernetes cluster
export VLAN_SEGMENT=${DEPLOY_NAME}
## Prefix of the VLAN segments created during deployment
## Change this to match the DEPLOY_NAME of the Kubernetes cluster if a different name is used above
export FACILITY=ewr1
## Facility to use for deployment (others can be found through Packet.com web portal)
## Ideally use the same FACILITY as the Kubernetes cluster
export NODE_GROUP_ONE_NAME=${DEPLOY_NAME}-pktgen
## Hostname of the packet generator server

###########################
#### Advanced settings ####
########################### 
export ISOLATED_CORES=0
## Number of cores to isolate through the kernel (isolcpus).
## 0 means isolate all cores except one on each socket for the operating system
export STATE_FILE=${PWD}/data/${DEPLOY_NAME}/packet_gen.tfstate
## Use a non-default STATE_FILE location
export NODE_FILE=${PWD}/data/${DEPLOY_NAME}/packet_gen.env
## Use a non-default NODE_FILE location
```

After updating the file, return to the CNF Testbed directory. From here, start server provisioning using the Makefile:
```
$ make hw_pktgen load_envs ${PWD}/tools/pktgen-example.env
## Update the path to the environment file if needed
```

After a few minutes the server will be provisioned. By default, the packet generator will be deployed with additional data visualization tools. This can be disabled by updating the vars section in `comparison/ansible/packet_generator.yml`:
```
visualization: true
## Change to 'false' to skip installing visualization tools
```

If the visualization is left enabled, more details on accessing and using this can be found [here](/docs/Visualization.md).

Once ready, continue with deploying the packet generator:
```
$ make pktgen load_envs ${PWD}/tools/pktgen-example.env
## Update the path to the environment file if needed
```

Once completed, SSH to the packet generator machine, where all the files needed to run the generator can be found in the `/root` directory. Start by having a look at `run_test.sh`, which has a few variables that can be configured:
```
RATES=( 10Gbps ndr_pdr )
## An array of tests to run, other examples are '5Mpps', 'pdr' or 'ndr'
ITERATIONS=1
## Number of iterations to run for the above RATES
DURATION=2
## Duration in seconds to generate packets. For pdr/ndr tests this is per step in the binary search
```

The `nfvbench_config.cfg` file can be used to further modify the configuration. For tests using the provided use cases [3c2n-csc](/examples/use_case/3c2n-csc) and [3c2n-csp](/examples/use_case/3c2n-csp) nothing needs to be changed, but for custom service chains the IP addresses and service chain count values may need to be updated.

Before use cases can be deployed, the MAC addresses of the packet generator must be collected. Run the generator and wait for the MACs to be printed as shown below:
```
$ ./run_tests.sh
(...)
Port 0: Ethernet Controller X710 for 10GbE SFP+ speed=10Gbps mac=aa:bb:cc:dd:ee:ff pci=0000:1a:00.1 driver=net_i40e
Port 1: Ethernet Controller X710 for 10GbE SFP+ speed=10Gbps mac=ff:ee:dd:cc:bb:aa pci=0000:1a:00.3 driver=net_i40e
## At this point the generator can be stopped using ctrl+c
```
