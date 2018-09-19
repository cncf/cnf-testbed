**Before running the vEdge CNF**

Make sure that the Docker prerequisites are installed. These can be installed by running `./install_docker_prereqs` in [comparison/cnf_edge_throughput](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput)

Make sure that the VPP vSwitch is already installed on the system - See [comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/README.md](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/README.md) for more details.

Ensure that the VPP vSwitch has the correct configuration by running `./reconfigure CNF` in [comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch) first.

**Running the vEdge CNF**

The vEdge CNF can be started (and built if necessary) by running `./run_container.sh`.

A running vEdge CNF can be removed with `./run_container.sh clean`

The CNF can be built without being started using `./build_container.sh`, and removed using `./build_container.sh clean`

**Show memory usage of vEdge CNF**

The "Resident Set Size" (RSS) memory usage of the vEdge CNF can be seen using `./get_rss.sh`  
