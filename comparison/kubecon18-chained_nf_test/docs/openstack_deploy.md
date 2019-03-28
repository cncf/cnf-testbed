# Deploy OpenStack to Packet

## Build the tools

It is assumed that all efforts start from a shell in the 'comparison' directory

On a machine with the cncf/cnfs project, and a docker capable enviornment (e.g. Linux with Docker, or a laptop with the Docker installed), and from a bash command line:

```
pushd ../tools
docker build -t ubuntu:packet_api -f packet_api/Dockerfile  packet_api/
docker build -t cnfdeploytools:latest -f deploy/Dockerfile deploy/
popd
```

## SSH access to build machines

In order to provision the hosts, it is necessary to have an SSH key pair including a private and public key on the same host as in the previous step, where the docker container is built and will be run.  A new key pair can be created on the same host, e.g.:

```
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
```

The public key from the newly generated key pair will need to be captured and included in the ssh keys registered with Packet.net so that it becomes possible to log into the deployed Packet.net nodes.

```
cat ~/.ssh/id_rsa.pub
```

## Deployment to Packet reserved instances

Steps to bring up an OpenStack cluster, Provision L2 Networking & VPP vSwitch

To Deploy the OpenStack cluster
1. Starting in the comparison directroy
3. Create os.env with Packet and cluster info.  (See ../tools/os.env.example or the example exports below)
   * Add your Packet Auth token with Network configuration capabilities
   * Add your Packet Project ID
   * Add your Packet Project Name (Quotes are needed to escape any spaces in the name)
4. Next source the os.env file and run the deploy script
   * Note that as this process can take approximately an hour, if you are running this test from a remote machine, it is recommended that you launch a session with a tool like `screen` in order to avoid a partial build if the session fails

```
screen
source os.env
../tools/deploy_openstack_cluster.sh
```

The deploy may take up to an hour, depending on the speed with which the Packet.net machines are built.

example os.env:
```
export NODE_NAME=os-
export NODE_COUNT=3
export NODE_PLAN=m2.xlarge.x86
export PACKET_OS=ubuntu_16_04
export PACKET_FACILITY=sjc1
export PACKET_AUTH_TOKEN=YOUR_API_KEY
export PACKET_PROJECT_ID=PROJECT_ID
export PACKET_PROJECT_NAME='Project Name'
```

Once the machines have built, log into the first host (the -1 machine from the Packet.net UI, or the first machine in the [all] section from the ansible/inventory file):

```
ssh {ip_of_first_machine}
```

Now we can complete the provisioning of the network and access lists for network security:

```
./create_security_groups.sh
./create_vlan.sh {vlan_id_from Packet.net Networks}
```

And finally we can provision a VM:

```
./create_instance.sh
```

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

