# Ansible playbooks
Environments can be deployed using the provided Ansible playbooks. Information on how to use these can be found below.

### Installing necessary tools
Run the below commands from this directory to prepare the cncfdeploytools container, which is used for running the playbooks.
```
pushd ../../tools
The packet_api and cnfdeploytools 
docker build -t ubuntu:packet_api -f packet_api/Dockerfile  packet_api/
docker build -t cnfdeploytools:latest -f deploy/Dockerfile deploy/
popd
```

### Running the cncfdeploytools container
To use the tool you must have a Packet.net API token available. Replace <PACKET_AUTH_TOKEN> below and run the commands from this directory.

The docker command will run the container and you should end up with a terminal pointed at the /terraform directory
```
cd ..
docker run -e PACKET_API_TOKEN=<PACKET_AUTH_TOKEN> -v $(pwd)/ansible:/ansible -v ~/.ssh/x1smallws01:/root/.ssh/id_rsa --entrypoint /bin/bash -ti cnfdeploytools:latest
```
In the container, switch to the ansible directory
```
cd /ansible
```

## Running the playbooks
The following section assumes that you are in the cncfdeploytools container (see above).

Unless otherwise noted, the following environment variables should be set before running any of the playbooks:
```
export PACKET_FACILITY=<Packet.net facility where your server(s) are running>
export DEPLOY_ENV=<Name of environment, used when creating VLANs (Will re-use VLANs if they already exist)>
export SERVER_LIST=<Hotname of server(s) to be used>
export PROJECT_NAME=<Name of Packet.net project>
```

Before deploying to a server, verify that it is accessible from the container using ssh
```
ssh root@<Server IP>
```

Below are notes on how to deploy different environments for use in testing and benchmarking.

### Packet Generator
Deploy a packet generator (NFVbench) on a single m2.xlarge (Mellanox NIC) or n2.xlarge* (Intel NIC, * Only tested on early HW)
```
ansible-playbook -i "<Server IP>," packet_generator.yml -e [dual_mellanox=true OR quad_intel=true]
```
Use `dual_mellanox=true` for m2.xlarge, and `quad_intel=true` for n2.xlarge.

_Note the comma (,) following the `<Server IP>`, which must be included._

Once deployed, two files can be found on the server, `nfvbench_config.cfg` and `run_nfvbench_test.sh`. The configuration file can be used to customize the NFVbench parameters, and the shell script is used to run tests.

For single chain deployments (currently not including Openstack) everything should be configured "out-of-the-box", but for multiple chains and Openstack deployments the nfvbench_config.cfg file must be updated with correct MACs, number of service chains and VLANs.
