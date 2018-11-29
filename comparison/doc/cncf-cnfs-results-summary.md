## Introduction

cncf-cnfs-results-summary.md

This note describes the benchmarking of VNF and CNF based software-based
network services running on a single compute node. FD.io VPP is used as
the open-source Network Function (NF). NF(s) are running either within
the VM(s), referred to as VNF(s), or within the Docker Container(s),
referred to as CNF(s). Ethernet frames are demultiplexed and multiplexed
from/to the two physical 10GbE interfaces thru a Linux User-Mode
Software Switch using FD.io VPP again.

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

1. FD.io CSIT 2n-skx testbed t22  (Xeon Platinum 8180)
2. packet.net 2n-skx testbed (Xeon Gold 6150)

## NFV Service Topologies

Benchmarked NFV service topologies:

1. VNF Service Chain (VSC) topology with Snake Forwarding
2. CNF Service Chain (CSC) topology with Snake Forwarding
3. CNF Service Pipeline (CSP) topology with Pipeline Forwarding

## Cores Allocation

### Linux User-Mode Switch

A single instance of Linux User-Mode Software (SW) Switch is running in a compute
node. Processor physical core allocation is as follows:

1. SW Switch has a set of Main Threads (control threads) and one or more of Dataplane Thread(s).
2. Separate thread to core subscription ratios are used for main and dataplane threads.
3. DTCR value determines the Dataplane Thread to Core Ratio, with target values=(..).
4. MTCR value determines the Main Thread to Core Ratio, with target values=(..).

Baseline tests are done with DTCR=1, MTCR=1.
Then with DTCR=..

### VNFs and CNFs

Per VNF or CNF instance processor physical core allocation:

1. Each NF has a set of Main Threads (control threads) and one or more of Dataplane Thread(s).
2. Separate thread to core subscription ratios are used for main and dataplane threads.
3. DTCR value determines the Dataplane Thread to Core Ratio, with target values=(1,2,4,8).
4. MTCR value determines the Main Thread to Core Ratio, with target values=(2,4,8).
5. Number of physical cores required is calculated as follows:
   * #cores=(#dt/dtcr)+(#mt/mtcr)            , where
   * #cores - total number of physical cores required and used.
   * #dt - total number of dataplane threads (1 or more per NF).
   * #mt - total number of main thread sets (1 set per NF).

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
    Row:    1..10  number of network service instances
    Column: 1..10  number of network functions per service instance
    Value:  1..NN  number of physical processor cores used
    Core Ratios: DTCR=1, MTCR=2
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

### FD.io CSIT 2n-skx, DTCR=1, MTCR=2

```
    Testbed: t22
    Row:     1..10  number of network service instances
    Column:  1..10  number of network functions (VNF or CNF) per service instance
    Value:   x.y    MRR throughput in [Mpps]
    Core Ratios: DTCR=1, MTCR=2
```

```
    VSC   001   002   004   006   008   010
    001   6.1   3.5   2.3   1.5   1.1   ???
    002   3.9   1.5   0.3   0.1   0.1   ---
    004   2.4   0.7   0.1   ---   ---   ---
    006   1.7   0.5   ---   ---   ---   ---
    008   1.4   ???   ---   ---   ---   ---
    010   ???   ---   ---   ---   ---   ---
```

```
    CSC   001   002   004   006   008   010
    001   6.4   3.8   2.2   1.6   1.2   ???
    002   5.8   3.4   1.8   1.2   0.9   ---
    004   5.6   3.2   1.6   ---   ---   ---
    006   5.4   3.1   ---   ---   ---   ---
    008   5.4   3.4   ---   ---   ---   ---
    010   ???   ---   ---   ---   ---   ---
```

```
    CSP   001   002   004   006   008   010
    001   6.3   6.3   6.3   6.4   6.5   ???
    002   5.8   5.6   5.6   5.6   5.5   ---
    004   5.6   5.5   5.3   ---   ---   ---
    006   5.4   5.3   ---   ---   ---   ---
    008   5.4   5.2   ---   ---   ---   ---
    010   ???   ---   ---   ---   ---   ---
```

### Packet.net 2n-skx, DTCR=1, MTCR=2

```
    Testbed: tg-quad01, sut-quad02-sut
    Row:     1..10  number of network service instances
    Column:  1..10  number of network functions (VNF or CNF) per service instance
    Value:   x.y    MRR throughput in [Mpps]
    Core Ratios: DTCR=1, MTCR=2
```

```
    VSC   001   002   004   006   008   010
    001   5.4   3.1   1.5   1.2   0.9   ---
    002   3.4   1.3   0.3   ---   ---   ---
    004   2.1   0.5   ---   ---   ---   ---
    006   1.5   ---   ---   ---   ---   ---
    008   1.1   ---   ---   ---   ---   ---
    010   ---   ---   ---   ---   ---   ---
```

```
    CSC   001   002   004   006   008   010
    001   5.6   3.3   1.9   1.3   1.0   ---
    002   5.1   2.9   1.5   ---   ---   ---
    004   4.9   2.7   ---   ---   ---   ---
    006   4.8   ---   ---   ---   ---   ---
    008   4.7   ---   ---   ---   ---   ---
    010   ---   ---   ---   ---   ---   ---
```

```
    CSP   001   002   004   006   008   010
    001   5.6   5.7   5.6   5.7   5.7   ---
    002   5.1   4.8   4.9   ---   ---   ---
    004   4.9   4.8   ---   ---   ---   ---
    006   4.8   ---   ---   ---   ---   ---
    008   4.7   ---   ---   ---   ---   ---
    010   ---   ---   ---   ---   ---   ---
```


### Pulling results from nvfbench logs

Latest results in comparison/baseline_nf_performance-csit/results/novlan

Gathering a summary of results from the nfvbench logs with:
```fgrep -R "|    Total    |" * | sort | awk -F '[ ]*[|][ ]*' '{print $1 " " $8 " (" $5 ")"}'```
