# Deploy K8s to Equinix Metal

See [common setup steps](steps_to_deploy_testbed.mkd#common-steps) for the cnf testbed.

## Build the tools

On a machine with a docker capable enviornment (e.g. Linux with Docker, or a laptop with the Docker installed), clone the cncf/cnf-testbed repo and run the following from a bash command line to build the deployment container images:

```
cd cnf-testbed/tools
docker build -t ubuntu:packet_api -f packet_api/Dockerfile  packet_api/
docker build -t cnfdeploytools:latest -f deploy/Dockerfile deploy/
```

## Access to build machines

Ensure SSH public/private key pair setup on [Equinix Metal](https://metal.equinix.com/) (in [common setup steps](steps_to_deploy_testbed.mkd#common-steps)) is available at $HOME/.ssh/id_rsa[.pub] on the workstation starting the deployment

If you're running on a local host or any other host outside of the cluster LAN, you will need to set your primary DNS to 147.75.69.23 and disable dnsmasq in order for the generated hostnames to be reachable 

## Deployment to Equinix Metal

Brings up a k8s cluster, provisions L2 Networking & installs VPP vSwitch on master and compute nodes

1. Create k8s-cluster.env with Equinix Metal and cluster info.  (See [k8s-cluster.env.example](tools/k8s-cluster.env.example))
   * Add your Equinix Metal Auth token with Network configuration capabilities
   * Add your Equinix Metal Project ID
   * Add your Equinix Metal Project Name (Quotes are needed to escape any spaces in the name)
   * Add your Equinix Metal Facility (for L2 provisioning)
   * Set NODE_PLAN to m2.xlarge for a Mellanox NIC machine and n2.xlarge for a Intel NIC machine
   * Set DEPLOY_ENV to generate VLAN descriptions or make use of pre-existing vlans (more on that below)
2. If using reserved instances, copy [k8s_worker_override.tf.disabled](tools/k8s_worker_override.tf.disabled) to k8s_worker_override.tf
    * `cp k8s_worker_override.tf.disabled k8s_worker_override.tf`
3. Next source the k8s-cluster.env file in the cnfs/tools dir, which has Equinix Metal API token, k8s version, node types ect - and deploy


    ```
    source k8s-cluster.env
    ./deploy_k8s_cluster.sh
    ```

Once deploy_cluster.sh is finished you will find you kubeconfig file under REPO/tools/data/kubeconfig

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
* quad port intel: 
  * vlan1 => eth1 (req)
  * vlan2 => eth2 (req)
  * vlan3 => eth3 (cluster mgmt)
* dual port Mellanox:
  * vlan1 => eth1
  * vlan2 => eth1


1. cross-cloud provisioner creates hosts via terraform and deploys kubernetes
2. when VPP is enabled (defualt) ansible-playbook runs the playbook specified in the .env file (default: k8s_worker_vswitch_mellanox.yml) to setup the k8s cluster L2 networking

EQUINIX METAL
  - create vlans (ansible)
  - remove ports from bond (ansible)
  - assign vlans to ports (ansible)

HOST
  - removes ports from bond on worker nodes (ansible)
  - sets up vpp on worker node (ansible)

## VPP Vlan considerations with Equinix Metal

Equinix Metal projects are limited to a maximum of 12 virtual networks. Because of this, the ability to create vlans dynamically may become limited depending on the number of co-existing test environments. These playbooks are configured to re-use dynamically created VLANs but in some cases vlans may have been created ahead of time and need to be re-used. In such cases, one just needs to alter their configuration so that the generated name of the vlan matches the description of the vlan in the Equinix Metal environment. The playbook generates vlan names as such:

```
{deploy environment}vlan1
{deploy environment}vlan2
```

where deploy environment is the value of DEPLOY_ENV in your os-cluster.env environment variable. If finer grain control over the vlan name is needed, the 'vlan*n*' portion of generated names can be changed in the playbook (eg. k8s_worker_vswitch_mellanox.yml) under hosts["all"].vars.vlans
