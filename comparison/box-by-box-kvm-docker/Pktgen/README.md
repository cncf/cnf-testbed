# Packet Generator VNF

**Work in progress!**

Uses NFVbench generate traffic

Documentation available here: https://docs.opnfv.org/en/latest/submodules/nfvbench/docs/testing/user/userguide/index.html

### Limitations

Currently uses a TCP tunnel over localhost for interconnect, which limits the throughput to ~170K packets per second.

### VNF Setup

`vagrant up`

### Starting the packet generator

SSH to the VNF

`vagrant ssh Pktgen`

Start the packet generator

(low number of packets per second)
`nfvbench`

(configurable number of packets per second)
`nfvbench --rate=<PPS>pps`
