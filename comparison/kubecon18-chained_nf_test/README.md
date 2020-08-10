# Comparing chained network function CNF deployment models

This directory provides a way to reproduce chained vnf vs cnf testing results.

---
## What is the goal?

#### To compare the performance of NF's on Openstack and Kubernetes with a reproducable set of steps.
- Using packet.net for bare metal provisioning
- Minimal user prerequisite software (ssh,git,docker)
- Minimal scripted steps to setup, execute tests and destroy 

---

## Where are we now 12/18 ?

# Need to fill in the blanks
- Hand altering of BIOS and GRUB for quad port Intel NIC's


---

## Example pictures showing test topologies for comparison

![network_overview](https://user-images.githubusercontent.com/40474606/48859161-9536f500-ed7a-11e8-88a9-627d2b3c79ec.png)

# Any other pictures needed here?
![openstack](https://raw.githubusercontent.com/cncf/cnfs/master/docs/images/openstack_overview.jpg)


---
## Openstack testbed details
- Openstack version
- Openstack installation details?
# Need to fill in the blanks

---
## Kubernetes testbed details
- K8s version
# Need to fill in the blanks


---
## Worker/compute Equipment in use at packet hosting CNF and VNFs

The Kubernetes and Openstack clusters will have 2-3 machines which run the network functions.

Specs at a glance:

- CPU: Dual socket Xeon Gold 5120 (2.2Ghz)
- Cores: 24 per CPU (48 total)
- Memory: 384 GB of DDR4 ECC
- Storage: 3.2 TB of NVMe Flash
- NIC: Quad port Intel x710


The system hardware configuration is based on the [Packet m2.xlarge.x86](https://www.packet.com/cloud/servers/m2-xlarge/).

The default [dual port Mellanox ConnectX-4 NIC](https://www.dell.com/en-us/shop/mellanox-connectx-4-lx-dual-port-25gbe-da-sfp-rndc-customer-install/apd/406-bblh/networking) has been replaced by [quad port Intel x710 NIC.](https://www.dell.com/en-us/shop/dell-intel-x710-quad-port-10gb-da-sfp-network-daughter-card/apd/555-bckl/networking).  The NIC ports are connected to 10GbE ports on the top-of-rack switches.



---

## Test Results

[Current results directory](https://github.com/cncf/cnfs/tree/master/comparison/kubecon18-chained_nf_test/results)

# Links for extensive results or nfvbench logs?
---




## Executing the  comparison test

Caveats: 
- As of 12/18 the Quad port Intel NIC is not publically available. It should become publically available in Q1/19.**
- Some custom BIOS changes will be needed for Quad port Intel 
- This documentation assumes you have a [packet] account.


**CNCF is not responsible for any charges on your packet.net account.  Please verify that all servers are deleted when your testing is completed via the [Packet Portal](https://app.packet.net)**

---

## Steps to execute performance test

1. Install prereq software on your desktop machine
    1. [docker](https://docs.docker.com/install/)
    1. [git](https://help.github.com/articles/set-up-git/)

1. Create [packet] account

1.  Create [packet account setup] variables

    1. preserve your project ID UUID in 
    1. create and preserve project-specific api key
    1. add your personal ssh key


1. Setup environment (dual mellanox test)
    1. Clone the test repository 
    1. Change into the test directory
    1. create global environment file from template
    1. edit global.env file with packet.net details
    1. load environment  variables
    ```
    git clone --depth 1 git@github.com:cncf/cnfs.git
    cd cnfs/comparison/kubecon18-chained_nf_test
    cp template.env global.env
    emacs global.env
    . ./global.env  
    ```
1. Kubernetes deploy and test execution 
    1. Build k8s cluster on packet 
        1. [quad intel additional steps](https://github.com/cncf/cnfs/tree/master/docs/quad_intel_install.md)
    1. packet Layer 2 setup
    1. Execute k8s test

    ```
    ./deploy_k8s_test_case
    ./????packet_l2_setup
    ./run_k8s_test_case
    ```
# Still need final script names and locations


1. Openstack deploy and test execution
    1. Build Openstack cluster on packet
        1. [quad intel additional steps](https://github.com/cncf/cnfs/tree/master/docs/quad_intel_install.md)
    1. packet Layer 2 setup
    1. Execute Openstack test
    ```
    ./deploy_openstack_test_case
    ./????packet_l2_setup
    ./run_openstack_test_case
    ``
# Still need final script names and locations


# Where do people go looking for results?

[packet]: https://www.packet.net "Packet.net"
[packet account setup]: https://help.packet.net/article/13-portal#display--description "packet setup"
