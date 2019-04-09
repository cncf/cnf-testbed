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


## Layer 2 Configuration

By default, the openstack_chef_create.yaml playbook will set up VPP as the openstack Layer 2. This behaviour is controlled by the following vars in the playbook:

```
  vars:
    vpp_network: true
    vpp_ver: 1807
    vpp_branch: '18.07'
    vpp_commit: stable/1807
    create_vlans: true
    create_masquerade: true
```

* vpp_network - When set to false, OVS will be deployed as the L2 instead
* create_vlans - When set to false, the VLANs for the packet hosts will not be automatically created in packet and configured in the packet hosts
* create_masquerade - When set to false, the playbook will not create the openstack vlan and subnet representations in openstack, nor will it add the iptables nat masquerade postroute rule to allow internet access from openstack compute hosts
    * Note: this setting is dependent on facts set during the create_vlans portion of the playbook and therefore create_vlans must be true for this functionality to work

To override the layer 2 settings, update your `os-cluster.env` file's ANSIBLE_ARGS export to include your updated variables starting with the -e (extra-vars) flag. For multiple variables, wrap them in escaped quotes seperated by a space delimeter like such:

`export ANSIBLE_ARGS="-e \"vpp_network=false create_vlans=false create_masquerade=false\""`

## VPP Vlan considerations with packet

Packet projects are limited to a maximum of 12 virtual networks. Because of this, the ability to create vlans dynamically may become limited depending on the number of co-existing test environments. These playbooks are configured to re-use dynamically created VLANs but in some cases vlans may have been created ahead of time and need to be re-used. In such cases, one just needs to alter their configuration so that the generated name of the vlan matches the description of the vlan in the packet environment. The playbook generates vlan names as such:

```
{deploy environment}testvlan1
{deploy environment}testvlan2
```

where deploy environment is the value of DEPLOY_ENV in your os-cluster.env environment variable. If finer grain control over the vlan name is needed, the 'testvlan*n*' portion of generated names can be changed in openstack_chef_install.yml under hosts["all"].roles["packet_l2"].vars.vlans

