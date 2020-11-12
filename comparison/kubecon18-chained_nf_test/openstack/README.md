# Install OpenStack on Equinix Metal bare metal with Chef

To launch OpenStack in [Equinix Metal](https://metal.equinix.com/), we'll leverage a number of tools in order to automate as much of the process as possible. This will inculde:

* Terraform
* Ansible
* Chef

In order to avoid installing terraform and ansible on our local machine, we'll instead create and run a local container, which will then run our terraform and initial ansible provisioning code.   The code will then install Chef, and the requisite Chef cookbooks in order to launch the OpenStack services.

## Build host setup

We will be making use of a docker container (and building it) locally, so a version of Docker does need to be installed on your local machine.

For a Mac build machine:
https://docs.docker.com/docker-for-mac/install/

For a Windows build machine:
https://docs.docker.com/docker-for-windows/install/

For a Linux machine, you can install via yum, apt, snap etc:
https://docs.docker.com/install
Then pick your favorite flavor.

Or run the following:

```
bash <(curl -sL https://get.docker.com)
```

Once your docker environment is in existence, we will want to clone the CNCF/CNFS git repository, either by using the git client if you have one installed:

```
git clone --depth 1 https://github.com/cncf/cnfs.git
```

Or by downloading and extracting the latest bundle:
https://github.com/cncf/cnfs/archive/master.zip

Once you have the repository on the build machine, we can build a Docker container that will allow us to launch our instance:

```
cd cnfs/comparison/kubecon18-chained_nf_test/openstack
docker build -t cnfdeploytools:latest  ../../../tools/deploy/
```

## SSH "root" key for Ansible
Now we have an image, but we still need some credentials both _in_ [Equinix Metal](https://metal.equinix.com/) (speciifcally an ssh public key), and for the local machine.  First, we need to make sure that the ssh key that is associated with the shell that is going to launch the docker container we built in the previous step is available, as the launch scripts expect to use the default ssh private key to connect via ansible.  In addition, the code expects that file to be called id_rsa and the public key to be called id_rsa.pub.  There is also an expectation that these keys are in the /root/.ssh/ directory.

It is also necessary to upload the id_rsa.pub key into the [Equinix Metal Console](http://console.equinix.com/) as a public key associated with, and with access to the project that is going to be targeted by the installer.

## Equinix Metal Project and API Keys

After the ssh key has been uploaded, we need to create a file (or add to our shell environment) for two environment variables:

```
export PACKET_PROJECT_ID=abcdef12-b8a8-435e-b8b7-123445689abc
export PACKET_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
The project ID is available in the project settings tab of the [Equinix Metal Console](http://console.equinix.com/), and the AUTH Token is called an API Token in the Console.

## Public IP Addressing

In order for external access to be possible in the Equinix Metal environment, we'll want to ask for a set of additional IP addresses that we can then associate with our controller.  The initial reqquest is done in the Network section of the Project.  Often, an 8 address block may be adequate for a small test system, and larger blocks can be allocated to the system in the same fashion.

Once the block is requested (and occasionally run through the Equinix Metal approval process), we can capture the lowest order IP address and the CIDR netmask, and we will use that information later to add the addresses to our controller host.

## L2 Tenant networks

If L2 tenant networks are going to be used in the Equinix Metal environment (perhaps with a tool like VPP), it is necessary to capture that information up front as well, and as we do not currently automate this proces, it is also necessary to create the networks in the Equinix Metal Console, and again, mark down the specific VLAN IDs provided for the VLANs created.

## Host buildout and configuration

We're now at a point where we have our build image, we have our security credentials defined, and we have the network information we'll need for the deployment

**Deploy an OpenStack cluster to Equinix Metal**

```
docker build -t cnfdeploytools:latest  ../../../tools/deploy/
```

Set the environment variables for the project id (PACKET_PROJECT_ID), API key (PACKET_AUTH_TOKEN)

Optionally, specify the facility (PACKET_FACILITY) and machine type (PACKET_MASTER_DEVICE_PLAN)

Example usage:

```
git clone --depth 1 https://github.com/cncf/cnfs.git
cd cnfs/comparison/openstack_chained_nf_test/deploy_openstack
export PACKET_PROJECT_ID=YOUR_EQUINIX_METAL_PROJECT_ID
export PACKET_AUTH_TOKEN=YOUR_EQUINIX_METAL_API_KEY
export PACKET_FACILITY="sjc1"
export PACKET_MASTER_DEVICE_PLAN="m2.xlarge.x86"
```

Then run the setup script.  This process will create a terraform driven deployment and an ansible based inventory that can be used to extend and update the environment.
```
./setup_openstack.sh
```

The terraform state should end up in ../../../tools/ansible-terraform/openstack.tfstate
The ansible inventory will end up in ../../ansible/inventory


Provisioning an existing system (assuming you are in the setup script directory):
```
docker run -v $(pwd)/../../ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa  --entrypoint /usr/bin/ansible -ti cnfdeploytools:latest -i /ansible/inventory /ansible/openstack_chef_install.yml
```

