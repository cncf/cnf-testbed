# Deploy OpenStack to Packet

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

Steps to bring up an OpenStack cluster, Provision L2 Networking & VPP vSwitch

_To Deploy the OpenStack cluster_
1. Create openstack-cluster.env with Packet and cluster info.  (See [os-cluster.env.example](tools/os-cluster.env.example))
   * Add your Packet Auth token with Network configuration capabilities
   * Add your Packet Project ID
   * Add your Packet Project Name (Quotes are needed to escape any spaces in the name)
   * Set NODE_PLAN to m2.xlarge for a Mellanox NIC machine and n2.xlarge for a Intel NIC machine
2. If using reserved instances, copy [reserved_override.tf.disabled](tools/terrafrom-ansible/reserved_override.tf.disabled) to override.tf
3. Next source the openstack-cluster.env file and run the deploy script
   * Note that as this process can take approximately an hour, if you are running this test from a remote machine, it is recommended that you launch a session with a tool like `tmux` or `screen` in order to avoid a partial build if the session fails


```
cd tools
cp terraform-ansible/reserved_override.tf.disabled terraform-ansible/override.tf
source openstack-cluster.env
./deploy_openstack_cluster.sh
```

The deploy may take up to an hour, depending on the speed with which the Packet.net machines are built.


---

The Openstack deploy can also be done in stages as follows

#### Provision packet machines

Packet web ui or `PROVISION_ONLY=true ./deploy_openstack_cluster.sh`

#### Issue: Packet Terraform provider bug causes reserved instances to not be added to it's state file

Because of a [Terraform Packet provider bug](https://github.com/cncf/cnf-testbed/issues/215) the inventory file for ansible does not contain the server IPs.  If the ansible inventory file does not contain the new server IPs, then add manually adding them is required.

```
[etcd]
{node_1_ip}
{node_2_ip}
.
.
.
{node_n_ip}
[all]
```



Run `PROVISION_ONLY=true ./deploy_openstack_cluster.sh` again to finish setting up the systems

#### Deploy OpenStack and setup the VPP vSwitch

Run `SKIP_PROVISIONING=true ./deploy_openstack_cluster.sh` again to finish setting up the systems


---


### Testing

1. SSH to the control node.  Eg.  ssh {ip_of_first_machine}

2. Load the Openstack env config `source openrc`

3. Run the `./create_instance.sh` script to create a VM


For arbitrary Openstack CLI commands (e.g. listing servers deployed):

```
source openrc
openstack server list
```


## Overview setup and steps

VLAN assignments
quad port intel:
{not yet supported}
  vlan1 => eth1 (req)
  vlan2 => eth2 (req)
  vlan3 => eth3 (cluster mgmt)

dual port Mellanox:
   vlan1 => eth1
   vlan2 => eth1


1. cross-cloud (terraform)
2. terraform-ansible runs the playbook openstack_infra_create.yml 
3. openstack_infra_create.yml playbook sets up nodes (ntp, GRUB config, etc.)
4. start script then launches ansible-playbook with openstack_chef_create.yaml playbook
  - set up chef and openstack recipes
  - runs chef in local mode to configure a single "control/network" node and "compute" node
  - runs further ansible to set up vpp, and the openstack newtork-vpp driver
  - sets up the etcd instance needed for VPP functionality
  - configures nova-compute for hugepage support
  - sets up a default flavor (id: 1) for hugepages support
  - installs the xenial ubuntu image

There are still a few manual steps:

1. security groups and vlans need to be manually created

