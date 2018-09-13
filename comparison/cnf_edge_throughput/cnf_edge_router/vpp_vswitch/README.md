# VPP vSwitch setup for the CNF Edge Througput comparison

Pre-req:
- Install VPP software


Goal: Configure VPP for bridging traffic from public network (Layer-2 on Packet.net) to container over memif.


Configuration steps:
- Create / update the main VPP configuration file, `/etc/vpp/startup.conf`, using the content from [comparison/cnf_edge_router/vpp_vswitch/etc/vpp/startup.conf](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/startup.conf)
- Create / update the  VPP configuration file, `/etc/vpp/setup.gate`, using the content from [comparison/cnf_edge_router/vpp_vswitch/etc/vpp/setup.gate](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/setup.gate)
- Create a `/etc/vpp/sockets` folder


---

Additional example configuration are in  [comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/examples](https://github.com/cncf/cnfs/tree/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/examples)
