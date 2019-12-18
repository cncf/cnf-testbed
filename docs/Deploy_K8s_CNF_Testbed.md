# Steps to deploy CNF Testbed

_Updated December 18th, 2019_

_Small changes to filenames_

This document will show how to set up a CNF Testbed environment. Everything will be deployed on servers hosted by [Packet](https://www.packet.com/).

## Prerequisites
Before starting the deployment you will need access to a project on Packet. Note down the **PROJECT_NAME** and **PROJECT_ID**, both found through the Packet web portal, as these will be used throughout the deployment for provisioning servers and configuring the network.

You should also make sure that you have a keypair available for SSH access. You can add your public key to the project on Packet through the web portal, which ensures that you will have passwordless SSH access to all servers used for deploying the CNF Testbed.

## Prepare workstation / jump server
Once the project on Packet has been configured, start by creating a server (x1.small.x86, Ubuntu 18.04 LTS) to use as workstation for deploying and managing the CNF Testbed.

Once the machine is running, start by installing the initial dependencies:
```
$ apt update
$ apt install -y git \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

## Install Docker (from https://docs.docker.com/install/linux/docker-ce/ubuntu/)
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
$ apt update
$ apt install -y docker-ce docker-ce-cli containerd.io

## Install Kubectl (from https://kubernetes.io/docs/tasks/tools/install-kubectl/)
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ mv ./kubectl /usr/local/bin/kubectl

## Clone CNF Testbed
$ git clone https://github.com/cncf/cnf-testbed.git
```

Then, create a keypair on the workstation:
```
## Save as default: id_rsa
$ ssh-keygen -t rsa -b 4096
```

Add this key to the project on Packet as well, since it will be used throughout the CNF Testbed installation.

Update `/etc/resolv.conf` with the following addresses:
```
nameserver 147.75.69.23
nameserver 8.8.8.8
```

Restart the resolved service:
```
$ service systemd-resolved restart
```

Change to the CNF Testbed directory created previously (default: cnf-testbed).
from here go to the `tools/` directory and run the following commands:
```
$ docker build -t ubuntu:packet_api -f packet_api/Dockerfile  packet_api/
$ docker build -t cnfdeploytools:latest -f deploy/Dockerfile deploy/
```

Except for setting up an Ansible environment as shown below the workstation is ready to use, and unless otherwise noted commands will be run from this machine.

## Deploy Ansible environment
Certain parts of the CNF Testbed are done directly using Ansible playbooks. The easiest way to run these is to set up an interactive container on the workstation server using "cnfdeploytools", which has been build previously.

If you want to avoid running the container each time you need to run a playbook, you can use `tmux`, `screen` or similar to keep it running in the background. Start by going to the `cnf-testbed` directory and follow the below steps:
```
## Create a "screen" terminal
$ screen -S <name>
  # Replace <name>
  # Disconnect screen with ctrl+a - d
  # Enter screen with "screen -r <name>"
  # List screens with "screen -ls"
## Running the "cnfdeploytools" container
$ cd ~/cnf-testbed
$ docker run -e PACKET_API_TOKEN=<Auth token> -v $(pwd)/comparison/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa --entrypoint /bin/bash -ti cnfdeploytools:latest
  # Replace <Auth token> with the key for your project at Packet
$$ cd /ansible/
```
When running commands in the Ansible container, each line will be prepended with `$$` instead of `$` when in the host.

This container environment is not used for deploying the K8s clusters. When the environment is needed it will be mentioned (deploying packet generator and CNFs)

## Deploy K8s cluster
This section will show how to deploy one or more K8s clusters on Packet. The examples used here will deploy 1 master and 1 worker node, with the option to scale it out prior to deployment.

There are a few options available when deploying a K8s cluster, as there are two different types of servers (Intel or Mellanox NIC) available, and when using Intel NIC it is possible to run the host vSwitch (VPP) either in the host or in a container.

Start by going to the `tools/` directory. Copy the `k8s-cluster.env.example` file and rename it as you see fit (for this guide the filename `k8s-cluster.env` is used). The content of the file is described below. Some of the version/release variables should not be changed unless necessary.
```
export NAME=quadintel
  # This is the unique name for the deployment
export K8S_DEPLOY_ENV=k8sworker
  # This is used to handle VLANs in the project on Packet
  # VLANs will be created in a PACKET_FACILITY scope (see below)
  # VLANs are named as "{K8S_DEPLOY_ENV}vlan"
  # This can be used to re-use VLANs for multiple clusters
export MASTER_NODE_COUNT=1
  # The number of master nodes in the cluster
export WORKER_NODE_COUNT=1
  # The number of worker nodes in the cluster
export MASTER_NODE_TYPE=t1.small
  # The server type to use for the master node
export WORKER_NODE_TYPE=m2.xlarge.x86 # Mellanox NIC
  # WORKER_NODE_TYPE specifies what type of server (and NIC) to use for the worker
  # "m2.xlarge.x86" uses Mellanox Connectx4
  # "n2.xlarge.x86" uses Intel X710  
#export WORKER_NODE_TYPE=n2.xlarge.x86 # Intel NIC
  # See above
export NODE_OS=ubuntu_18_04
  # Specifies the OS to be used
  # Only tested with Ubuntu 18.04 LTS
export PACKET_FACILITY=ewr1
  # The Packet facility to use for the cluster
  # This can be used with "K8S_DEPLOY_ENV" to re-use VLANs on different deployments
export ETCD_VERSION=v3.2.8
  # etcd version (do not change)
export CNI_VERSION=v0.6.0
  # CNI version (do not change)
export K8S_RELEASE=v1.12.2
  # K8s release (do not change)
export PLAYBOOK=k8s_worker_vswitch_mellanox.yml # Mellanox NIC
  # PLAYBOOK should be set to match the "WORKER_NODE_TYPE" specified above
  # For Mellanox NIC: "k8s_worker_vswitch_mellanox.yml"
  # For Intel NIC: "k8s_worker_vswitch_quad_intel.yml"
#export PLAYBOOK=k8s_worker_vswitch_quad_intel.yml # Intel NIC
  # See above
export PACKET_AUTH_TOKEN=your-auth-token
  # The auth token for your project at Packet
export PACKET_PROJECT_ID=your-project-id
  # The project ID for your project at Packet
export PACKET_PROJECT_NAME="CNCF Testbed" # CNCF Testbed is default, this must be set if using another project
  # The name of your project at Packet
```

If you specified `WORKER_NODE_TYPE=n2.xlarge.x86` and `PLAYBOOK=k8s_worker_vswitch_quad_intel.yml` in the environment file above, there is another small step before deploying. Go back to the `cnf-testbed/` directory and then open the file `comparison/ansible/k8s_worker_vswitch_quad_intel.yml`. In this file looks for the `vswitch_container` line, which can be modified:
```
- hosts: all
  vars:
    (...)
    vswitch_container: false
      # Specifies how the host vSwitch (VPP) is installed on the worker nodes
      # If false: vSwitch is installed as a host service
      # If true: vSwitch is installed in a container on the host
```

Once this has been configured, so back to the `tools/` directory. At this point you can consider using `tmux`, `screen` or similar to ensure a persistent terminal in case of connectivity issues. Otherwise we are ready to deploy the K8s cluster:
```
$ source k8s-cluster.env
$ ./deploy_k8s_cluster.sh
```

If the playbooks completes successfully, you should be able to find your new machines and VLANs in the Packet web portal under your project. You should be able to SSH to the machines from the workstation using the IPs listed at Packet.

At this point, go ahead and make a backup of the `kubeconfig` file which can be found in `cnf-testbed/tools/data`, as this can be useful when deploying CNFs. To make the file available from inside the Ansible environment (container), the `kubeconfig` file should be placed somewhere in the `cnf-testbed/comparison/ansible` directory. You can rename the file as you see fit.

If you want to deploy multiple clusters, update the `k8s-cluster.env` file (at least change "NAME") and source the file. Also, delete the `.pem` files found in `tools/data/` before running `deploy_k8s_cluster.sh` again.

## Deploy packet generator
To test the network performance of the K8s clusters, we need to configure a packet generator. This will run on a separate server in your project on Packet, and must be configured with the same deploy environment (VLANs) as the clusters.

Start by provisioning a server using the Packet web portal:
  * Hostname: Select a hostname that makes the server easily identifiable
  * Location: Same location used in `PACKET_FACILITY` while deploying K8s clusters
  * Type: `n2.xlarge.x86` (preferred) or `m2.xlarge.x86`
  * OS: Ubuntu 18.04 LTS (if using `n2.xlarge.x86`) or Ubuntu 16.04 LTS (if using `m2.xlarge.x86`)

Once the server has been provisioned note down the `IP` and `hostname`. On the workbench, create an Ansible environment (see above) or use one you have created already.

In the Ansible container, start by connecting via SSH to the packet generator server:
```
$$ ssh <Packet generator IP>
  # You will need to answer "yes" to the prompt on connecting
$$ exit
  # Leave the packet generator machine, and return to the container
```

Start by setting the following environment variables in the container:

```
$$ export PACKET_FACILITY=<Facility>
  # Use the same facility as the server (and K8s clusters) are deployed in
  # e.g. ewr1, sjc1
$$ export DEPLOY_ENV=<Deploy environment>
  # Use the same environment as the K8s cluster (K8S_DEPLOY_ENV)
$$ export SERVER_LIST=<Hostname>
  # Hostname of the server
$$ export PROJECT_NAME="<Project name>"
  # Name of the project on Packet
```

With the environment defined, the packet generator can be installed. Note the comma (,) following `<Server IP>`, which must be included:
```
# When using "n2.xlarge.x86"
$$ ansible-playbook -i "<Server IP>," packet_generator.yml -e quad_intel=true
  # <Server IP> is the same address used for SSH connectivity earlier
# When using "m2.xlarge.x86"
$$ ansible-playbook -i "<Server IP>," packet_generator.yml -e dual_mellanox=true
  # <Server IP> is the same address used for SSH connectivity earlier
```

Once the playbook is finished, you can disconnect from the Ansible container. Then go ahead and SSH to the packet generator machine, and run the following command:
```
$ ./run_test.sh
```

Let it run for a bit until you see the following lines:
```
## When using "n2.xlarge.x86" (Intel NIC)
INFO    Port 0: Ethernet Controller X710 for 10GbE SFP+ speed=10Gbps mac=e4:43:4b:56:c4:32 pci=0000:1a:00.2 driver=net_i40e
INFO    Port 1: Ethernet Controller X710 for 10GbE SFP+ speed=10Gbps mac=e4:43:4b:56:c4:33 pci=0000:1a:00.3 driver=net_i40e

## When using "m2.xlarge.x86" (Mellanox NIC)
INFO    Port 0: MT27710 Family [ConnectX-4 Lx Virtual Function] speed=10Gbps mac=92:b0:2a:54:68:a7 pci=0000:5e:00.4 driver=net_mlx5
INFO    Port 1: MT27710 Family [ConnectX-4 Lx Virtual Function] speed=10Gbps mac=96:e7:a9:37:7d:1c pci=0000:5e:00.5 driver=net_mlx5
```

Note down the two MAC addresses, as these will be needed when deploying CNFs. You can now go ahead and stop the generator (ctrl+c) and disconnect from the packet generator machine.

## Deploy CNFs
Currently there are 3 defined test-cases that can be deployed using an included Ansible playbook:
* 3c2n-csp: 3 chains of 2 nodes each, connected directly ("Pipeline")
* 3c2n-csc: 3 chains of 2 nodes each, connected via host vSwitch ("Snake")
* ipsec : 1 chain of 4 nodes, with connections both directly and through the host vSwitch using IPsec tunneling

Before CNFs can be deployed, the playbook needs to be updated with the MAC addresses of the packet generator that were collected during the deployment. Open `cnf-testbed/comparison/ansible/deploy_cnfs.yml` and update the MAC addresses:
```
- hosts: all
  vars:
    (...)
    nfvbench_macs:
      - "<MAC address #1>"
      - "<MAC address #2>"
```

At this point, make sure the `kubeconfig` file from the deployment is avaialble somewhere in the `cnf-testbed/comparison/ansible` directory. Once this is done, enter the Ansible environment (container) on the workstation.

Inside the Ansible environment, change directory to `/ansible/'. Now go ahead and set the following environment variable:
```
$$ export K8S_AUTH_KUBECONFIG=</path/to/kubeconfig>
  # The cnf-testbed/comparison/ansible host directory is mapped to /ansible inside the container
```

Also, make sure that the K8s worker is accessible through SSH from the ansible environment:
```
$$ ssh <K8s worker IP>
```

At this point we are ready to deploy the test-cases. One thing to note is that the playbook supports two different deployment methods:
* Docker (default): CNFs are deployed using Docker on the K8s worker.
  - Using this approach, CNFs are not managed by K8s
* K8s: CNFs are deployed through K8s from the workstation / ansible environment
  - Utilizes the OpenShift Python client [k8s_module](https://docs.ansible.com/ansible/latest/modules/k8s_module.html)
  - CNFs are managed by K8s and located in the "cnf" namespace

The CNF test-cases are deployed using a provided playbook:
```
$$ ansible-playbook -i "<K8s worker IP>," -e use_case=<test-case> [-e k8s=True] [-e privileged=False] deploy_cnfs.yml
  # <K8s worker IP> is the same IP used for SSH. Make sure to add the trailing comma (,) after the IP.
  # <test-case> can be: 3c2n-csp, 3c2n-csc or ipsec
  # [-e k8s=True] is used to specify the K8s deployment method
  # [-e privileged=False] is used to run CNFs in unprivileged mode
```

Re-running the script with different options (towards the same K8s worker IP) will automatically remove existing CNFs and update the host vSwitch (VPP) as needed.

## Run traffic benchmark
With a CNF test-case deployed, we can go ahead and SSH from the workbench to the packet generator machine:
```
$ ssh <Packet generator IP>
```

On the packet generator machine, verify that the NFVbench container is running:
```
$ docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS               NAMES
cd67d2f82722        opnfv/nfvbench:2.0.5   "/nfvbench/docker/nf…"   26 hours ago        Up 2 hours                              nfvbench
  # Example output, but verify the "STATUS" as "Up"
```

If the container has exited (e.g. following a reboot), start it again using `docker start nfvbench`.
By default, NFVbench (the traffic generator) is configured to run against either of the `3c2n-*` test-cases, so if you are running the `ipsec` test-case, you will need to update the `nfvbench_config.cfg` file with the following options (search the file for the key and update the value):
```
# ipsec test-case
service_chain_count: 1
mac_addrs_left: ['52:54:00:00:00:aa']
  # You can comment out the existing and uncomment this line, as it is already in the file
mac_addrs_right: ['52:54:00:00:00:bb']
  # You can comment out the existing and uncomment this line, as it is already in the file
vlans: [<VLAN#1>, <VLAN#2>]
  # You can comment out the existing and uncomment this line, as it is already in the file
  
# 3c2n-* test-cases (configured by default)
service_chain_count: 3
mac_addrs_left: ['52:54:00:00:00:aa', '52:54:01:00:00:aa', '52:54:02:00:00:aa']
  # You can comment out the existing and uncomment this line, as it is already in the file
mac_addrs_right: ['52:54:00:00:00:bb', '52:54:01:00:00:bb', '52:54:02:00:00:bb']
  # You can comment out the existing and uncomment this line, as it is already in the file
vlans: [[<VLAN#1>, <VLAN#1>, <VLAN#1>], [<VLAN#2>, <VLAN#2>, <VLAN#2>]]
  # You can comment out the existing and uncomment this line, as it is already in the file
```

If you have updated the configuration file, go ahead and restart the container:
```
$ docker restart nfvbench
```

Before running the benchmark, open `run_test.sh` to check or modify the test settings. Some useful option examples and information can be found below:
```
CHAINS="${1:-3}"
  # Number of chains being benchmarked (defaults to 3 as in the 3c2n-* test-cases)
  # Only used for naming output files
NODES="${2:-2}"
  # Number of nodes per chain being benchmarked (defaults to 2 as in the 3c2n-* test-cases)
  # Only used for naming output files
PREFIX="${3:-cnf}"
  # Prefix to be added to the output files (defaults to "cnf")
RATES=( 10Gbps ndr_pdr )
  # The tests/benchmarks to be performed
  # 10Gbps: Static test with 10Gbps traffic (can be changed, e.g. 5Gbps or 5Mpps)
  # ndr_pdr: Binary search benchmark(s) to find the NDR and PDR throughput
ITERATIONS=1
  # The number of iterations of each test specified in "RATES"
DURATION=30
  # The duration of each test / benchmark
  # For the ndr_pdr test each step in the search will take 30 seconds
```

Once everything is configured, the benchmark can be started. If you are running multiple tests and iterations it is advised to use `tmux`, `screen` or similar to avoid an unexpected disconnect. The benchmark can then be started using:
```
./run_test.sh [Chains] [Nodes] [Prefix]
  # The 3 optional arguments can be used to override the values configured previously
```

Once the benchmark completes, results will be available in the `results/` directory.

## Run NSM Packet-filtering example
To show the functionality of [Network Service Mesh](https://github.com/networkservicemesh/networkservicemesh) on CNF Testbed, one of the [examples](https://github.com/networkservicemesh/examples) provided by the team can be deployed through an ansible playbook.
```
    +--------+
    |        |
    | Kernel |
    | Client +-------+
    |        |       |
    +--------+       |       ----------------+                +---------+
                     +------->               |  10.60.2.0/24  |         | 10.60.1.0/24
               10.60.3.0/24  | Packet Filter +----------------> Gateway +-------------->
                     +------->               |                |         |
    +--------+       |       +---------------+                +---------+
    |        |       |
    |  VPP   +-------+
    | Client |
    |        |
    +--------+
```

Before running the example, make sure you have a K8s cluster and an ansible environment available (see above sections).

To deploy and test, do the following steps:
```
## In the ansible environment
$$ cd /ansible/
$$ export KUBECONFIG=</path/to/kubeconfig>
  # The cnf-testbed/comparison/ansible host directory is mapped to /ansible inside the container
$$ ansible-playbook deploy_nsm.yml [-e reuse=true]
  # The optional reuse option can be used for skipping cleanup and redeployment of the containers/CNFs
  # The connectivity test will run regardless of the option
```

The playbook starts by deploying the NSM infrastructure using an included Helm chart. Once NSM is deployed, the 4 CNFs are deployed as Kubernetes deployments.

Once the playbook finishes, you should see output similar to the below, indicating connectivity between the Kernel Client / VPP Client and Gateway is successful (the VPP Client is described as ucnf-client in the output):
```
ok: [localhost] => {
    "msg": [
        "pod/gateway-b56bcb689-p9vwv condition met",
        "pod/packet-filter-7c9fb57cd9-rjzjs condition met",
        "pod/simple-client-76c8478495-bmwpg condition met",
        "pod/ucnf-client-5cd6bb6ffc-g5rm2 condition met",
        "===== >>>>> PROCESSING simple-client-76c8478495-bmwpg  <<<<< ===========",
        "Try 1",
        "PING 10.60.3.2 (10.60.3.2): 56 data bytes",
        "64 bytes from 10.60.3.2: seq=0 ttl=64 time=2.009 ms",
        (...)
        "64 bytes from 10.60.3.2: seq=9 ttl=64 time=4.859 ms",
        "",
        "--- 10.60.3.2 ping statistics ---",
        "10 packets transmitted, 10 packets received, 0% packet loss",
        "round-trip min/avg/max = 2.009/2.371/4.859 ms",
        "NSC simple-client-76c8478495-bmwpg with IP 10.60.3.1/30 pinging vpn-gateway-nse TargetIP: 10.60.3.2 successful",
        "PING 10.60.2.2 (10.60.2.2): 56 data bytes",
        "64 bytes from 10.60.2.2: seq=0 ttl=63 time=3.275 ms",
        (...)
        "64 bytes from 10.60.2.2: seq=9 ttl=63 time=3.173 ms",
        "",
        "--- 10.60.2.2 ping statistics ---",
        "10 packets transmitted, 10 packets received, 0% packet loss",
        "round-trip min/avg/max = 2.106/3.074/3.275 ms",
        "NSC simple-client-76c8478495-bmwpg with IP 10.60.3.1/30 pinging vpn-gateway-nse TargetIP: 10.60.2.2 successful",
        "All check OK. NSC simple-client-76c8478495-bmwpg behaving as expected.",
        "===== >>>>> PROCESSING ucnf-client-5cd6bb6ffc-g5rm2  <<<<< ===========",
        "Try 1",
        "116 bytes from 10.60.3.6: icmp_seq=1 ttl=64 time=2.1475 ms",
        "116 bytes from 10.60.3.6: icmp_seq=2 ttl=64 time=2.2173 ms",
        "116 bytes from 10.60.3.6: icmp_seq=3 ttl=64 time=2.1433 ms",
        "",
        "Statistics: 3 sent, 3 received, 0% packet loss",
        "NSC ucnf-client-5cd6bb6ffc-g5rm2 with IP 10.60.3.5/30",
        " pinging ucnf-endpoint TargetIP: 10.60.3.6 successful",
        "116 bytes from 10.60.2.2: icmp_seq=1 ttl=63 time=3.2145 ms",
        "116 bytes from 10.60.2.2: icmp_seq=2 ttl=63 time=3.2853 ms",
        "116 bytes from 10.60.2.2: icmp_seq=3 ttl=63 time=3.2367 ms",
        "",
        "Statistics: 3 sent, 3 received, 0% packet loss",
        "NSC ucnf-client-5cd6bb6ffc-g5rm2 with IP 10.60.3.5/30",
        " pinging ucnf-endpoint TargetIP: 10.60.2.2 successful"
    ]
}
```

To remove the CNFs and NSM, the following steps can be used from inside the ansible environment:
```
$$ kubectl delete deployments --all
  # This will delete all deployments in the default namespace
$$ helm delete $(helm list -q)
  # This will delete anything deployed through Helm
```

