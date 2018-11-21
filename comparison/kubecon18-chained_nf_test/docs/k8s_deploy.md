# Deploy k8s

## Build the tools

```
pushd ../tools
docker build -t ubuntu:packet_api -f packet_api/Dockerfile  packet_api/
docker build -t cnfdeploytools:latest .
popd
```


## Deployment to Packet reserved instances

Steps to bring up a K8s cluster, Provision L2 Networking & VPP vSwitch

To Deploy the k8s cluster
1. First find the reserved instance id that you want to use as a k8s worker node on packet.net, this can be done by clicking deploy server in the packet.net gui and there should be a list of reserved servers available and their associated ids
2. Once found, update the k8s_worker_override.tf file under cnfs/tools with the desired id
3. Create k8s.env with Packet and cluster info.  (See k8s.env.example)
4. Next source the k8s.env file in the cnfs/tools dir, which has packet api token, k8s version, node types ect - and deploy

```
source k8s.env
../tools/deploy_cluster.sh
Once deploy_cluster.sh is finished you will find you kubeconfig file under 
REPO/tools/data/kubeconfig
```

To Provision the L2 Networking & VPP on the worker node, first find the hostname of the worker node provisioned the above step, by default it is set to packet-worker-1.packet.packet.local

Next run the ansible tools container and run the ansible script.
```
docker run -e PACKET_API_TOKEN=$PACKET_AUTH_TOKEN -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v $(pwd)/../ansible:/ansible --entrypoint /bin/bash -ti cnfdeploytools:latest

cd /ansible

ansible-playbook -i "147.75.65.117," k8s_worker_vswitch_quad_intel.yml -e server_list=packet-worker-1.packet.packet.local -e deploy_env=k8sworker
```

## Overview setup and steps

VLAN assignments
quad port intel:
  vlan1 => eth1 (req)
  vlan2 => eth2 (req)
  vlan3 => eth3 (cluster mgmt)

dual port Mellanox:
   vlan1 => eth1
   vlan2 => eth1


1. cross-cloud (terraform)
2. terraform-ansible runs the playbook k8s_cluster.yml 
3. k8s_cluster.yml playbook include playbooks to setup k8s cluster
4. quad_intel_workers.yml (set interfaces var to Packet interfaces)

PACKET
  - create vlans (ansible)
  - remove ports from bond (ansible)
  - assign vlans to ports (ansible)

HOST
  - removes ports from bond on worker nodes (ansible)
  - sets up vpp on worker node (ansible)


