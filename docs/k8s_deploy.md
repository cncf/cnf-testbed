# Deploy K8s to Packet

See [common setup steps](steps_to_deploy_testbed.mkd#common-steps) for the cnf testbed.

## Build the tools

On a machine with the cncf/cnf-testbed repo and a docker capable enviornment (e.g. Linux with Docker, or a laptop with the Docker installed) run the following from a bash command line:

```
cd tools
docker build -t ubuntu:packet_api -f packet_api/Dockerfile  packet_api/
docker build -t cnfdeploytools:latest -f deploy/Dockerfile deploy/
```

## SSH access to build machines

Ensure SSH public/private key pair setup on Packet (in [common setup steps](steps_to_deploy_testbed.mkd#common-steps)) is available at $HOME/.ssh/id_rsa[.pub] on the workstation starting the deployment

## Deployment to Packet reserved instances

Steps to bring up a K8s cluster, Provision L2 Networking & VPP vSwitch

_To Deploy the k8s cluster_
1. Create k8s-cluster.env with Packet and cluster info.  (See [k8s-cluster.env.example](tools/k8s-cluster.env.example))
   * Add your Packet Auth token with Network configuration capabilities
   * Add your Packet Project ID
   * Add your Packet Project Name (Quotes are needed to escape any spaces in the name)
   * Set NODE_PLAN to m2.xlarge for a Mellanox NIC machine and n2.xlarge for a Intel NIC machine
2. If using reserved instances, copy [k8s_worker_override.tf.disabled](tools/k8s_worker_override.tf.disabled) to k8s_worker_override.tf
3. Next source the k8s-cluster.env file in the cnfs/tools dir, which has packet api token, k8s version, node types ect - and deploy


```
source k8s-cluster.env
../../tools/deploy_k8s_cluster.sh
#Once deploy_cluster.sh is finished you will find you kubeconfig file under 
REPO/tools/packet-data/kubeconfig
```

To Provision the L2 Networking & VPP on the worker node, first find the hostname of the worker node provisioned the above step, by default it is set to packet-worker-1.packet.packet.local

Next run the ansible tools container
```
docker run -e PACKET_API_TOKEN=$PACKET_AUTH_TOKEN -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v $(pwd)/../ansible:/ansible --entrypoint /bin/bash -ti cnfdeploytools:latest
```

Using ansible code:
```
cd /ansible

ansible-playbook -i "IP_OF_WORKER," k8s_worker_vswitch_quad_intel.yml -e server_list=HOST_NAME_OF_WORKER -e deploy_env=k8sworker
```

Deploy a container:
```
export KUBECONFIG=../../tools/packet-data/kubeconfig
pushd ./CNF/k8s/helm
helm install --name cnf1 ./vedge/
## (If Tiller isn't installed: helm init --service-account tiller)
```

Looking at the CNFs running in K8s:
- list pods - `kubectl get pods`
- get logs for container - `kubectl logs vpp-vedge-65dc445f9d-wmd66`
- get details on the container - `kubectl describe pods vpp-vedge-65dc445f9d-wmd66`

Destroy the container: `helm del --purge cnf1`



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


