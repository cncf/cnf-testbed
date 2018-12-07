## NFV Service Density Benchmarking

## Introduction

This note describes the benchmarking of VNF and CNF based software-based
network services running on a single compute node, referred to as NFV
service density benchmarking. FD.io VPP is used as the open-source
Network Function (NF). NF(s) are running either within the VM(s),
referred to as VNF(s), or within the Docker Container(s), referred to as
CNF(s). Ethernet frames are demultiplexed and multiplexed from/to the
two physical 10GbE interfaces thru a Linux User-Mode Software Switch
using FD.io VPP again.

The same version of FD.io VPP application running in VNFs and CNFs are
configured as a IPv4 routing Network Fuction, routed-forwarding between
two (virtual)software interfaces, virtio in VNFs and memif in CNFs.

The same version of FD.io VPP application, running Linux User-Mode as a
(virtual) software Switch, is configured as a Ethernet L2 Bridge with
in-line dataplane MAC learning, L2 switched-forwarding between multiple
(virtual) software interfaces, vhostuser for inter-connected VNFs and
memif for inter-connected CNFs.

## Environments

Benchmarked physical test environments:

1. FD.io CSIT 2n-skx testbed t22 (Xeon Platinum 8180)
2. packet.net 2n-skx testbed (Xeon Gold 6150)

ADD outputs of lspci for above

ADD number of usable cores for above
  system
  switch
  NFs

## NFV Service Topologies

Benchmarked NFV service topologies:

1. VNF Service Chain (VSC) topology with Snake Forwarding
2. CNF Service Chain (CSC) topology with Snake Forwarding
3. CNF Service Pipeline (CSP) topology with Pipeline Forwarding

## Cores Allocation

### Linux User-Mode Switch

A single instance of Linux User-Mode Software (SW) Switch is running in
a compute node. Every performance optimized SW Switch application has
two sets of software threads: i) Main threads, handling Switch
application management and control planes, and ii) Dataplane threads,
handling dataplane packet processing and forwarding.

This applies to FD.io VPP used in this benchmarking.

Allocation of processor physical cores to the software switch is as
follows:

1. Two mapping ratios are defined and used in software switch
   benchmarking:
   * `pcdr4sw` value determines Physical Core to Dataplane Ratio for SWitch.
   * `pcmr4sw` value determines Physical Core to Main Ratio for SWitch.
2. Target values to be benchmarked:
   * pcdr4sw = [(1:1),(2:1),(4:1)].
   * pcmr4sw = [(1:1),(1:2)].
3. Number of physical cores required for the benchmarked software switch
   is calculated as follows:
   *     #pc = pcdr4sw * #dsw + pcmr4sw * #msw
   * where
   *     #pc - total number of physical cores required and used.
   *     #dsw - total number of switch dataplane thread sets (1 set per SW switch).
   *     #msw - total number of switch main thread sets (1 set per SW switch).

### CNFs and VNFs

Multiple instances of NFs (CNFs or VNFs) are running in a compute node.
Every performance optimized NF has two sets of software threads: i) Main
threads, handling NF application management and control planes, and ii)
Dataplane threads, handling NF dataplane packet processing and
forwarding.

This applies to FD.io VPP used in this benchmarking.

Allocation of processor physical cores per NF instance is as
follows:

1. Two mapping ratios are defined and used in NF service matrix
   benchmarking:
   a. `pcdr4nf` value determines Physical Core to Dataplane Ratio for NF.
   b. `pcmr4nf` value determines Physical Core to Main Ratio for NF.
2. Target values to be benchmarked:
   a. pcdr4nf = [(1:1),(1:2),(1:4)].
   b. pcmr4nf = [(1:2),(1:4),(1:8)].
3. Number of physical cores required for the benchmarked NFs' service
   matrix is calculated as follows:
   *     #pc = pcdr4nf * #dnf + pcmr4nf * #mnf
   * where
   *     #pc  - total number of physical cores required and used.
   *     #dnf - total number of NF dataplane thread sets (1 set per NF instance).
   *     #mnf - total number of NF main thread sets (1 set per per NF instance).

## Service Density Matrix – Network Function View

```
  Row:    1..10  number of network service instances
  Column: 1..10  number of network functions per service instance
  Value:  1..100 total number of network functions within node
```

```
  SVC   001   002   004   006   008   010
  001     1     2     4     6     8    10
  002     2     4     8    12    16    20
  004     4     8    16    24    32    40
  006     6    12    24    36    48    60
  008     8    16    32    48    64    80
  010    10    20    40    60    80   100
```

## Service Density Matrix – Core Usage View

```
  Row:          1..10 number of network service instances
  Column:       1..10 number of network functions per service instance
  Value:        1..NN number of physical processor cores used
  Cores Numa0:  pcdr4sw = (1:1), pcmr4sw = (1:1)
                pcdr4nf = (1:1), pcmr4nf = (1:2)
  Cores Numa1:  not used
```

```
  SVC   001   002   004   006   008   010
  001     2     3     6     9    12    15
  002     3     6    12    18    24    30
  004     6    12    24    36    48    60
  006     9    18    36    54    72    90
  008    12    24    48    72    96   120
  010    15    30    60    90   120   150
```

## Methodology - MRR Throughput

MRR tests measure the packet forwarding rate under the maximum load
offered by traffic generator over a set trial duration, regardless of
packet loss. Maximum load for specified Ethernet frame size is set to
the bi-directional link rate.

## Service Density Matrix – MRR Throughput Results (L2 size=64B)

* Maximum Receive Rate (MRR) throughput results is measured in [Mpps]
* [Mpps] mega (millions) packets-per-second
* Encapsulation: IPv4 over untagged Ethernet
* IPv4 size: 46 Bytes
* Ethernet frame size: 64 Bytes

### FD.io CSIT 2n-skx, pcdr4sw = (1:1)

```
  Testbed:      t22

  Row:          1..10 number of network service instances
  Column:       1..10 number of network functions (VNF or CNF) per service instance
  Value:        x.y MRR throughput in [Mpps]
                x.y* `*` Indicates many retries due to failing nfvbench warm-up phase used to verify service forwarding path
                ??? to be measured
                --- configuration impossible for specific skx processor model, out of physical cores

  Ring sizes:   VNF vring_size = 256 (old qemu), CNF memif_ring_size = 1024

  Cores Numa0:  pcdr4sw = (1:1), pcmr4sw = (1:1)
                pcdr4nf = (1:1), pcmr4nf = (1:2)
  Cores Numa1:  not used
```

```
64B                                          IMIX
  VSC   001   002   004   006   008   010      VSC   001   002   004   006   008   010
  001   6.1   3.5   2.3   1.5   1.1   ???      001   ???   ???   ???   ???   ???   ???
  002   3.9   1.5   0.3   0.1   0.1   ---      002   ???   ???   ???   ???   ???   ---
  004   2.4   0.7   0.1   ---   ---   ---      004   1.9   0.5   0.1   ---   ---   ---
  006   1.7   0.5   ---   ---   ---   ---      006   1.4   0.4   ---   ---   ---   ---
  008   1.4   ???*  ---   ---   ---   ---      008   1.1   ???*  ---   ---   ---   ---
  010   ???   ---   ---   ---   ---   ---      010   ???   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSC   001   002   004   006   008   010      CSC   001   002   004   006   008   010
  001   6.4   3.8   2.2   1.6   1.2   ???      001   ???   ???   ???   ???   ???   ???
  002   5.8   3.4   1.8   1.2   0.9   ---      002   ???   ???   ???   ???   ???   ---
  004   5.6   3.2   1.6   ---   ---   ---      004   3.8   ???   ???   ---   ---   ---
  006   5.4   3.1   ---   ---   ---   ---      006   ???   ???   ---   ---   ---   ---
  008   5.4   3.4   ---   ---   ---   ---      008   3.4   1.9   ---   ---   ---   ---
  010   ???   ---   ---   ---   ---   ---      010   ???   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSP   001   002   004   006   008   010      CSP   001   002   004   006   008   010
  001   6.3   6.3   6.3   6.4   6.5   ???      001   ???   ???   ???   ???   ???   ???
  002   5.8   5.6   5.6   5.6   5.5   ---      002   ???   ???   ???   ???   ???   ---
  004   5.6   5.5   5.3   ---   ---   ---      004   3.7   3.5   3.3   ---   ---   ---
  006   5.4   5.3   ---   ---   ---   ---      006   3.6   3.3   ---   ---   ---   ---
  008   5.4   5.2   ---   ---   ---   ---      008   3.5   3.2   ---   ---   ---   ---
  010   ???   ---   ---   ---   ---   ---      010   ???   ---   ---   ---   ---   ---
```

### Packet.net 2n-skx, pcdr4sw = (1:1)

```
  Testbed:      tg-quad01, sut-quad02-sut

  Row:          1..10 number of network service instances
  Column:       1..10 number of network functions (VNF or CNF) per service instance
  Value:        x.y MRR throughput in [Mpps]
                x.y* `*` Indicates many retries due to failing nfvbench warm-up phase used to verify service forwarding path
                ??? to be measured
                --- Configuration impossible for specific skx processor model, out of physical cores

  Ring sizes:   VNF vring_size = 256 (old qemu), CNF memif_ring_size = 1024

  Cores Numa0:  pcdr4sw = (1:1), pcmr4sw = (1:1)
                pcdr4nf = (1:1), pcmr4nf = (1:2)
  Cores Numa1:  not used
```

```
64B                                          IMIX
  VSC   001   002   004   006   008   010      VSC   001   002   004   006   008   010
  001   5.4   3.1   1.5   1.2   0.9   ---      001   ???   ???   ???   ???   ???   ---
  002   3.4   1.3   0.3   ---   ---   ---      002   2.4   0.8   0.2   ---   ---   ---
  004   2.1   0.5   ---   ---   ---   ---      004   1.6   0.3   ---   ---   ---   ---
  006   1.5   ---   ---   ---   ---   ---      006   1.2   ---   ---   ---   ---   ---
  008   1.1   ---   ---   ---   ---   ---      008   0.9   ---   ---   ---   ---   ---
  010   ---   ---   ---   ---   ---   ---      010   ---   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSC   001   002   004   006   008   010      CSC   001   002   004   006   008   010
  001   5.6   3.3   1.9   1.3   1.0   ---      001   ???   ???   ???   ???   ???   ---
  002   5.1   2.9   1.5   ---   ---   ---      002   3.1   1.6   0.8   ---   ---   ---
  004   4.9   2.7   ---   ---   ---   ---      004   3.0   1.4   ---   ---   ---   ---
  006   4.8   ---   ---   ---   ---   ---      006   2.9   ---   ---   ---   ---   ---
  008   4.7   ---   ---   ---   ---   ---      008   2.8   ---   ---   ---   ---   ---
  010   ---   ---   ---   ---   ---   ---      010   ---   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSP   001   002   004   006   008   010      CSP   001   002   004   006   008   010
  001   5.6   5.7   5.6   5.7   5.7   ---      001   ???   ???   ???   ???   ???   ---
  002   5.1   4.8   4.9   ---   ---   ---      002   3.1   3.0   2.8   ---   ---   ---
  004   4.9   4.8   ---   ---   ---   ---      004   3.0   2.8   ---   ---   ---   ---
  006   4.8   ---   ---   ---   ---   ---      006   2.9   ---   ---   ---   ---   ---
  008   4.7   ---   ---   ---   ---   ---      008   2.8   ---   ---   ---   ---   ---
  010   ---   ---   ---   ---   ---   ---      010   ---   ---   ---   ---   ---   ---
```

### FD.io CSIT 2n-skx, pcdr4sw = (2:1)

```
  Testbed:      t22

  Row:          1..10 number of network service instances
  Column:       1..10 number of network functions (VNF or CNF) per service instance
  Value:        x.y MRR throughput in [Mpps]
                x.y* `*` indicates many retries due to failing nfvbench warm-up phase used to verify service forwarding path
                ??? to be measured
                --- Configuration impossible for specific skx processor model, out of physical cores

  Ring sizes:   VNF vring_size = 256 (old qemu), CNF memif_ring_size = 1024

  Cores Numa0:  pcdr4sw = (2:1), pcmr4sw = (1:1)
                pcdr4nf = (1:1), pcmr4nf = (1:2)
  Cores Numa1:  not used
```

```
64B                                          IMIX
  VSC   001   002   004   006   008   010      VSC   001   002   004   006   008   010
  001   6.9*  2.6   3.3   2.4   1.8   ???      001   4.0*  1.5   1.6   1.2   0.9   ???
  002   6.1   2.5   0.5   0.2   0.1   ---      002   3.8   1.5   0.3   0.1   0.1   ---
  004   4.3   1.0   0.2   ---   ---   ---      004   3.3   0.7   0.2   ---   ---   ---
  006   3.0   ???*  ---   ---   ---   ---      006   2.4   ???*  ---   ---   ---   ---
  008   2.3   ???*  ---   ---   ---   ---      008   1.9   ???*  ---   ---   ---   ---
  010   ???   ---   ---   ---   ---   ---      010   ???   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSC   001   002   004   006   008   010      CSC   001   002   004   006   008   010
  001   7.0*  6.0   3.7   2.6   2.1   ???      001   5.1*  4.0   1.8   1.3   1.0   ???
  002  11.8   6.7   4.0   2.8   2.2   ---      002   7.4   3.5   2.0   1.3   1.0   ---
  004  10.7   6.8   3.9   ---   ---   ---      004   6.8   3.7   1.9   ---   ---   ---
  006  10.4   6.6   ---   ---   ---   ---      006   6.5   3.6   ---   ---   ---   ---
  008  10.3   6.4   ---   ---   ---   ---      008   6.5   3.5   ---   ---   ---   ---
  010   ???   ---   ---   ---   ---   ---      010   ???   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSP   001   002   004   006   008   010      CSP   001   002   004   006   008   010
  001   7.0*  6.9*  6.9*  6.9*  6.9*  ???      001   5.1*  5.0*  4.6*  4.2*  4.0*  ???
  002  11.8  11.7  11.7  11.7  11.7   ---      002   7.4   7.2   6.8   6.4   6.1   ---
  004  10.7  10.7  10.5   ---   ---   ---      004   6.8   6.4   5.9   ---   ---   ---
  006  10.4  10.3   ---   ---   ---   ---      006   6.5   6.1   ---   ---   ---   ---
  008  10.3  10.1   ---   ---   ---   ---      008   6.5   5.9   ---   ---   ---   ---
  010   ???   ---   ---   ---   ---   ---      010   ???   ---   ---   ---   ---   ---
```

### Packet.net 2n-skx, pcdr4sw = (2:1)

```
  Testbed:      tg-quad01, sut-quad02-sut
  Row:          1..10 number of network service instances
  Column:       1..10 number of network functions (VNF or CNF) per service instance
  Value:        x.y MRR throughput in [Mpps]
                x.y* `*` Indicates many retries due to failing nfvbench warm-up phase used to verify service forwarding path
                ??? to be measured
                --- configuration impossible for specific skx processor model, out of physical cores

  Ring sizes:   VNF vring_size = 256 (old qemu), CNF memif_ring_size = 1024

  Cores Numa0:  pcdr4sw = (2:1), pcmr4sw = (1:1)
                pcdr4nf = (1:1), pcmr4nf = (1:2)
  Cores Numa1:  not used
```

```
64B                                           IMIX
  VSC   001   002   004   006   008   010       VSC   001   002   004   006   008   010
  001   6.3*  5.0   3.0   2.1   ---   ---       001   3.8*  2.4   1.4   1.0   ---   ---
  002   5.5   2.1   ---   ---   ---   ---       002   3.3   1.3   ---   ---   ---   ---
  004   4.0   ---   ---   ---   ---   ---       004   1.7   ---   ---   ---   ---   ---
  006   2.8   ---   ---   ---   ---   ---       006   1.2   ---   ---   ---   ---   ---
  008   ---   ---   ---   ---   ---   ---       008   ---   ---   ---   ---   ---   ---
  010   ---   ---   ---   ---   ---   ---       010   ---   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSC   001   002   004   006   008   010      CSC   001   002   004   006   008   010
  001   6.0*  5.3   3.2   2.3   ---   ---      001   5.1*  3.0   1.5   1.1   ---   ---
  002  10.4   6.0   ---   ---   ---   ---      002   6.0   2.9   ---   ---   ---   ---
  004   9.5   ---   ---   ---   ---   ---      004   5.7   ---   ---   ---   ---   ---
  006   9.2   ---   ---   ---   ---   ---      006   5.5   ---   ---   ---   ---   ---
  008   ---   ---   ---   ---   ---   ---      008   ---   ---   ---   ---   ---   ---
  010   ---   ---   ---   ---   ---   ---      010   ---   ---   ---   ---   ---   ---
```

```
64B                                          IMIX
  CSP   001   002   004   006   008   010      CSP   001   002   004   006   008   010
  001   6.2*  6.1*  6.1*  6.1*  ---   ---      001   5.1*  4.9*  4.2*  3.7*  ---   ---
  002  10.4  10.3   ---   ---   ---   ---      002   6.0   5.7   ---   ---   ---   ---
  004   9.5   ---   ---   ---   ---   ---      004   5.7   ---   ---   ---   ---   ---
  006   9.2   ---   ---   ---   ---   ---      006   5.5   ---   ---   ---   ---   ---
  008   ---   ---   ---   ---   ---   ---      008   ---   ---   ---   ---   ---   ---
  010   ---   ---   ---   ---   ---   ---      010   ---   ---   ---   ---   ---   ---
```

## Reading nfvbench logs

Throughput results generated by nfvbench are stored in following directories:

1. pcdr4sw = (1:1)
  * ```cnfs/comparison/baseline_nf_performance-csit/results/2t1c_novlan```
2. pcdr4sw = (2:1)
  * ```cnfs/comparison/baseline_nf_performance-csit/results/4t2c_novlan```

Pretty one-liner printouts per test can be obtained using ```jq``` json
parser and following commands run within the above results' directories:

```
jq -r '.benchmarks.network.service_chain.EXT.result.result."64".run_config."direction-total".rx | "64B \(.rate_pps)pps (\(.rate_bps)bps) " + input_filename' *pps*.json
```
```
jq -r '.benchmarks.network.service_chain.EXT.result.result.IMIX.run_config."direction-total".rx | "64B \(.rate_pps)pps (\(.rate_bps)bps) " + input_filename' *pps*.json
```
