# CNF chained nf test code

This project provides a way to reproduce chained vnf vs cnf testing results.

---

**The documentation in this README assumes you have a [packet] account.**

**Some tests require the current unreleased quad port intel machine currently in beta by packet.net.**

**CNCF is not responsible for any charges on your packet.net account.  Please verify that all servers are deleted when your testing is completed via the [Packet Portal](https://app.packet.net)**

---

## Example pictures showing test topologies

![openstack](https://github.com/cncf/cnfs/comparison/kubecon18-chained_nf_test/docs/images/openstack_overview.jpg)

## Steps to execute performance test


1. Install prereq software on your desktop machine
    1. [docker](https://docs.docker.com/install/)
    1. [git](https://www.github.com)

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
    git clone git@github.com:cncf/cnfs.git
    cd cnfs/comparison/kubecon18-chained_nf_test
    cp template.env global.env
    emacs global.env
    . .global.env  
    ```
1. Kubernetes deploy and test execution 
    1. Build k8s cluster on packet 
        1. [quad intel additional steps](https://github.com/cncf/cnfs/tree/master/comparison/kubecon18-chained_nf_test/docs/quad_intel_install.md)
    1. packet Layer 2 setup
    1. Execute k8s test

    ```
    ./deploy_k8s_test_case
    ./????packet_l2_setup
    ./run_k8s_test_case
    ```

1. Openstack deploy and test execution
    1. Build Openstack cluster on packet
        1. [quad intel additional steps](https://github.com/cncf/cnfs/tree/master/comparison/kubecon18-chained_nf_test/docs/quad_intel_install.md)
    1. packet Layer 2 setup
    1. Execute Openstack test
    ```
    ./deploy_openstack_test_case
    ./????packet_l2_setup
    ./run_openstack_test_case
    ``


[packet]: https://www.packet.net "Packet.net"
[packet account setup]: https://help.packet.net/article/13-portal#display--description "packet setup"