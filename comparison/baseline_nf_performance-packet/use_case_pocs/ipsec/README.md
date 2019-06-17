## IPsec use-case (Proof of concept)

### Pre-requisites:
Docker and VPP must be installed on SUT node (can be done through Ansible playbooks already in the repo).

### Before running:
* Update base/configure.sh (line 208) with MAC addresses of NFVbench/TRex
* Build the base image: `./build_container.sh`
  * Image can be removed using `./build_container.sh clean`

### Running:
* Run `./run_ipsec_poc.sh` and wait for it to complete
  * Verify containers are running using `docker ps`
  * c1n1Edge, c1n2Edge, c2n1Edge and c2n2Edge should all be up
  * Ensure that host VPP has been properly reconfigured (either in host or container depending on deployment)
* Run NFVbench from a different node
  * Configure it to run against 1 chain
* Containers can be removed using `./run_ipsec_poc.sh clean`

### Performance:
With the configuration and HW used for verification, throughput is around 480Kpps for the POC
