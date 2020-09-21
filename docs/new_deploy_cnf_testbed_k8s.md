# Deploy CNF Testbed Kubernetes Cluster

This document will show how to set up a CNF Testbed environment. Everything will be deployed on servers hosted by [Packet.com](https://www.packet.com/).

## Prerequisites
Before starting the deployment you will need access to a project on Packet. Note down the **PROJECT_NAME** and **PROJECT_ID**, both found through the Packet web portal, as these will be used throughout the deployment for provisioning servers and configuring the network. You will also need a personal **PACKET_AUTH_TOKEN**, which is created and found in personal settings under API Keys.

You should also make sure that you have a keypair available for SSH access. You can add your public key to the project on Packet through the web portal, which ensures that you will have passwordless SSH access to all servers used for deploying the CNF Testbed.

## Prepare workstation / jump server
Once the project on Packet has been configured, start by creating a server, e.g. x1.small.x86 with Ubuntu 18.04 LTS, to use as workstation for deploying and managing the CNF Testbed.

Once the workstation machine is running, start by installing the following dependencies:
```
$ apt update
$ apt install -y git \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
```

You will also need to install Docker prior to deploying the CNF Testbed:
```
## Install Docker (from https://docs.docker.com/install/linux/docker-ce/ubuntu/)
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
$ apt update
$ apt install -y docker-ce docker-ce-cli containerd.io
```

At this point you can clone to CNF Testbed:
```
## Clone CNF Testbed
$ git clone --depth 1 https://github.com/cncf/cnf-testbed.git
```

Optionally you can install Kubectl on the workstation, which is used to manage the Kubernetes cluster:
```
## Install Kubectl (from https://kubernetes.io/docs/tasks/tools/install-kubectl/)
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ mv ./kubectl /usr/local/bin/kubectl
```

Then, create a keypair on the workstation:
```
## Save as default: id_rsa
$ ssh-keygen -t rsa -b 4096
```

Add this key to the project on Packet as well, since it will be used throughout the CNF Testbed installation.

Change to the CNF Testbed directory created previously (default: cnf-testbed), and use the provided Makefile to install additional dependencies:
```
$ make deps
```

## Deploy CNF Testbed Kubernetes Cluster
This section will show how to deploy one or more K8s clusters on Packet. 

Start by going to the `tools/` directory. Copy or edit the [k8s-example.env](../tools/k8s-example.env) file (for this guide the filename `k8s-example.env` is used). The default content of the file is described below.
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
export VLAN_SEGMENT=${DEPLOY_NAME}
## Prefix of the VLAN segments created during deployment
export FACILITY=ewr1
## Facility to use for deployment (others can be found through Packet.com web portal)

#### Kubernetes "Master" Node Group ####
export NODE_GROUP_ONE_NAME=${DEPLOY_NAME}-master
## Name to append "group one" hostnames that are used for K8s master nodes
export NODE_GROUP_ONE_DEVICE_PLAN=c1.small.x86
## Instance type for nodes (others can be found through Packet.com web portal)
export NODE_GROUP_ONE_COUNT=1
## Number of nodes to deploy - Use an odd number to avoid errors with K8s deployment

#### Kubernetes "Worker" Node Group ####
export NODE_GROUP_TWO_NAME=${DEPLOY_NAME}-worker
## Name to append "group two" hostnames that are used for K8s worker nodes
export NODE_GROUP_TWO_DEVICE_PLAN=n2.xlarge.x86
## Instance type for nodes. Use either 'n2.xlarge.x86' or 'm2.xlarge.x86'
export NODE_GROUP_TWO_COUNT=1
## Number of nodes to deploy
# export PLAYBOOK=k8s_worker_vswitch_mellanox.yml
## Uncomment PLAYBOOK only if NODE_GROUP_TWO_DEVICE_PLAN=m2.xlarge.x86 (Mellanox NIC)

#### Extra Kubernetes "Worker" Node Group ####
export NODE_GROUP_THREE_NAME=${DEPLOY_NAME}-extra
## Name to append "group three" hostnames that are used for extra K8s worker nodes
export NODE_GROUP_THREE_DEVICE_PLAN=n2.xlarge.x86
## Instance type for nodes. Use either 'n2.xlarge.x86' or 'm2.xlarge.x86'
## If planning to install the vSwitch later, group two and three must use the same instance type
export NODE_GROUP_THREE_COUNT=0
## Number of nodes to deploy - By default the extra group is not used

###########################
#### Advanced settings ####
###########################
export OPERATING_SYSTEM=ubuntu_18_04
## Operating system deployed on all provisioned servers
export ISOLATED_CORES=0
## Number of cores to isolate through the kernel (isolcpus).
## 0 means isolate all cores except one on each socket for the operating system
export STATE_FILE=${PWD}/data/${DEPLOY_NAME}/terraform.tfstate
## Use a non-default STATE_FILE location
export NODE_FILE=${PWD}/data/${DEPLOY_NAME}/kubernetes.env
## Use a non-default NODE_FILE location
```

After updating the file, return to the CNF Testbed directory. From here, start server provisioning using the Makefile:
```
$ make hw_k8s load_envs ${PWD}/tools/k8s-example.env
## Update the path to the environment file if needed
```

After a few minutes the servers will be provisioned. Continue with deploying Kubernetes:
```
$ make k8s load_envs ${PWD}/tools/k8s-example.env
## Update the path to the environment file if needed
```

Once completed, the Kubernetes cluster is ready for use. If Kubectl is installed on the workstation machine, the kubeconfig file can be in found from the cnf-testbed directory in `${PWD}/data/${DEPLOY_NAME}/mycluster/artifacts/admin.conf`. Configure Kubectl to use this file, and check that the cluster is ready:
```
$ export KUBECONFIG="${PWD}/data/${DEPLOY_NAME}/mycluster/artifacts/admin.conf"
$ kubectl get nodes
```

Alternatively, kubectl can be used directory from the master node(s), without having to specify KUBECONFIG.
