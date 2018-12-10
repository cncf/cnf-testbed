# CNF/VNF - Edge Network Max Throughput Comparison

## Quick start with deployment code:

Steps to Deploy.

1. Clone Repo ```git clone git@github.com:cncf/cnfs.git```
2. Enter terraform dir ```cnfs/comparison/cnf_edge_throughput/```
3. Run Docker container with API/Token vars set ```docker run -v $(pwd):/packet -e TF_VAR_packet_api_key=PACKET-API-KEY -e TF_VAR_packet_project_id=PACKET-PROJECT-ID --entrypoint=/bin/bash -ti hashicorp/terraform:full```
4. cd to packet dir ```cd /packet```
5. Terraform provision ``` terraform init && terraform apply```

## Long version: Provisioning, installs, configuration and testing

**Instructions for deploying new machines from Packet.net web ui**

1. Log into the Packet.net dashboard at app.packet.net.  Select the org and project. (eg. CNCF, CNCF CNFs)
2. Click Servers
3. Click + New Servers button
4. Choose a hostname eg. cnf-edge-m2xl-04.
5. Choose Location
6. Choose m1.xlarge.x86 as Type
7. Choose Ubuntu 18.04 LTS as OS
8. Select desired SSH keys
9. Click Deploy Servers

**Layer-2 networking**

Next [setup Layer-2 networking](README-layer2-network.md)

**Install and configure common host software for the NFs**

See [README-NF-common.md](README-NF-common.md)


**Install Docker Prerequisities**

After cloning this repo

- `cd cnfs/comparison/baseline_nf_performance-packet`
- Run: [./install_docker_prereqs.sh](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet/install_docker_prereqs.sh)

**Install Vagrant Prerequisities**

After cloning this repo

- `cd cnfs/comparison/baseline_nf_performance-packet`
- Run: [./install_vagrant_prereqs.sh](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet/install_docker_prereqs.sh)

**Run VSC**

After cloning this repo

- `cd cnfs/comparison/baseline_nf_performance-packet/vEdge/VNF/VSC_multichain_shared`
- Run: [./run_vms.sh <chains> <nodeness> [clean]](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet/vEdge/VNF/VSC_multichain_shared/run_vms.sh)

**Run CSC**

After cloning this repo

- `cd cnfs/comparison/baseline_nf_performance-packet/vEdge/CNF/CSC_multichain_shared`
- Run: [./run_containers.sh <chains> <nodeness> [clean]](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet/vEdge/CNF/CSC_multichain_shared/run_containers.sh)

**Run CSC**

After cloning this repo

- `cd cnfs/comparison/baseline_nf_performance-packet/vEdge/CNF/CSP_multichain_shared`
- Run: [./run_containers.sh <chains> <nodeness> [clean]](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet/vEdge/CNF/CSP_multichain_shared/run_containers.sh)

**Traffic run**

After cloning this repo

- `cd cnfs/comparison/baseline_nf_performance-packet`
- Run: [./run_test_nfvbench.sh <chains> <nodeness> <test>(https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet/run_test_nfvbench.sh)

