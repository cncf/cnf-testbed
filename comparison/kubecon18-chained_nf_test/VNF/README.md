**Before running the vEdge VNF**

Make sure that the Vagrant prerequisites are installed. These can be installed by running `./install_vagrant_prereqs` in [comparison/cnf_edge_throughput](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput)

Make sure that the VPP vSwitch is already installed on the system - See [comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/README.md](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/README.md) for more details.

Ensure that the VPP vSwitch has the correct configuration by running `./reconfigure VNF` in [comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch) first.

Build the base image for the vEdge VNF. Details can be found in [comparison/cnf_edge_throughput/vEdge/VNF/base_image/README.md](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/vEdge/VNF/base_image/README.md)

**Running the vEdge VNF**

With the base image built, The vEdge VNF can be started by running `./run_vm.sh`.

A running vEdge VNF can be removed with `./run_vm.sh clean`

**Show memory usage of vEdge VNF**

The "Resident Set Size" (RSS) memory usage of the vEdge VNF can be seen using `./get_rss.sh`
