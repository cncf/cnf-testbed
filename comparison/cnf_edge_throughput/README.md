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


**Enable IOMMU and SR-IOV on the machines**

Reference: [NSM Notes for configuring VPP with Mellanox Connectx-4 (PFs and VFs)](https://github.com/ligato/networkservicemesh/issues/270#issue-355769450)

1. SSH into the server
2. `sed -i.bak 's/\(GRUB_CMDLINE_LINUX=\"\)/\1iommu=pt intel_iommu=on hugepagesz=2M hugepages=10240 isolcpus=2,4,6 nohz_full=2,4,6 rcu_nocbs=2,4,6 /' /etc/default/grub`
3. `update-grub2`
4. `reboot`


**Install Docker**

After cloning this repo

- `cd cnfs/comparison/cnf_edge_throughput`
- Run: [./install_docker_prereqs.sh](https://github.com/cncf/cnfs/tree/master/comparison/cnf_edge_throughput/install_docker_prereqs.sh)
