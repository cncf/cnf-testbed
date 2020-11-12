**Deploy an OpenStack cluster to Equinix Metal**

Start by ensuring that your system ssh keys are availiable under ~/.ssh/id_rsa and you have added the matching public key to your [Equinix Metal](https://metal.equinix.com/) account.

Set the environment variables for the project id (PACKET_PROJECT_ID), API key (PACKET_AUTH_TOKEN), facility (PACKET_FACILITY), machine type (PACKET_MASTER_DEVICE_PLAN) and OS (PACKET_OPERATING_SYSTEM).

Example usage:

```
git clone --depth 1 https://github.com/cncf/cnfs.git
cd cnfs/comparison/openstack_chained_nf_test/deploy_openstack
export PACKET_PROJECT_ID=YOUR_EQUINIX_METAL_PROJECT_ID
export PACKET_AUTH_TOKEN=YOUR_EQUINIX_METAL_API_KEY
export PACKET_FACILITY="sjc1"
export PACKET_MASTER_DEVICE_PLAN="x1.small.x86"
export PACKET_OPERATING_SYSTEM="ubuntu_16_04"
./deploy_openstack_cluster.sh
```

Provisioning an existing system:
```
docker build -t cnfdeploytools:latest  ../../../tools/deploy/
docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa  --entrypoint /bin/bash -ti cnfdeploytools:latest
cd /ansible
ansible-playbook -i "IP_OF_EQUINIX_METAL_MACHINE," main.yml
```

