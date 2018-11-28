cncf-cnfs-results-summary.md

[Current format: fixed width font with two whitespace nesting]
[Target format: markdown]

Benchmarked physical test environments:

  1. FD.io CSIT 2n-skx testbed t22  (Xeon Platinum 8180)
  2. packet.net 2n-skx testbed (Xeon Gold 6150)

Benchmarked NFV service design types:

  1. VNF Service Chain (VSC) topology with Snake Forwarding
  2. CNF Service Chain (CSC) topology with Snake Forwarding
  3. CNF Service Pipeline (CSP) topology with Pipeline Forwarding

Per VNF or CNF processory physical core allocation:

  1. Each NF has a set of Main Threads (control threads) and one or more of Dataplane Thread(s).
  2. Separate thread to core subscription ratios are used for main and dataplane threads.
  3. DTCR value determines the Dataplane Thread to Core Ratio, with target values=(1,2,4,8).
  4. MTCR value determines the Main Thread to Core Ratio, with target values=(2,4,8).
  5. Number of physical cores required is calculated as follows:
      #cores=(#dt/dtcr)+(#mt/mtcr)
      where
        #dt - total number of dataplane threads (1 or more per NF).
        #mt - total number of main thread sets (1 set per NF).

Service Density Matrix – Network Function View

  Row:    1..10  number of network service instances.
  Column: 1..10  number of network functions per service instance.
  Value:  1..100 total number of network functions within node.

  SVC   001   002   004   006   008   010
  001     1     2     4     6     8    10
  002     2     4     8    12    16    20
  004     4     8    16    24    32    40
  006     6    12    24    36    48    60
  008     8    16    32    48    64    80
  010    10    20    40    60    80   100

Service Density Matrix – Core Usage View

  Row:    1..10  number of network service instances.
  Column: 1..10  number of network functions per service instance.
  Value:  1..NN  number of physical processor cores used.
  Core Ratios: DTCR=1, MTCR=2.

  SVC   001   002   004   006   008   010
  001     2     3     6     9    12    15
  002     3     6    12    18    24    30
  004     6    12    24    36    48    60
  006     9    18    36    54    72    90
  008    12    24    48    72    96   120
  010    15    30    60    90   120   150

MRR Throughput Methodology

  MRR tests measure the packet forwarding rate under the maximum load
  offered by traffic generator over a set trial duration, regardless of
  packet loss. Maximum load for specified Ethernet frame size is set to
  the bi-directional link rate.

  Maximum Receive Rate (MRR) throughput results is measured in [Mpps]
    [Mpps] mega (millions) packets-per-second.
    Encapsulation: IPv4 over untagged Ethernet.
    IPv4 size: 46 Bytes.
    Ethernet frame size: 64 Bytes.

Service Density Matrix – MRR Throughput Results

  Row:    1..10  number of network service instances.
  Column: 1..10  number of network functions per service instance.
  Value:  XXX    MRR throughput in [Mpps].
  Core Ratios: DTCR=1, MTCR=2.

    FD.io CSIT 2n-skx testbed t22:

      VSC   001   002   004   006   008   010
      001   6.1   3.5   2.3   1.5   1.1   ???
      002   3.9   1.5   0.3   0.1   0.1   ---
      004   2.4   0.7   0.1   ---   ---   ---
      006   ???   ???   ---   ---   ---   ---
      008   ???   ???   ---   ---   ---   ---
      010   ???   ---   ---   ---   ---   ---

      CSC   001   002   004   006   008   010
      001   6.4   3.8   2.2   1.6   1.2   ???
      002   5.8   3.4   1.8   1.2   0.9   ---
      004   5.6   3.2   1.6   ---   ---   ---
      006   5.4   3.1   ---   ---   ---   ---
      008   5.4   3.3   ---   ---   ---   ---
      010   ???   ---   ---   ---   ---   ---

      CSP   001   002   004   006   008   010
      001   6.3   6.3   6.3   6.4   6.5   ???
      002   5.8   5.6   5.6   5.6   5.5   ---
      004   5.6   5.5   5.3   ---   ---   ---
      006   5.4   5.3   ---   ---   ---   ---
      008   5.4   5.2   ---   ---   ---   ---
      010   ???   ---   ---   ---   ---   ---

    packet.net 2n-skx testbed:

      VSC   001   002   004   006   008   010
      001   5.4   3.1   1.5   1.2   0.9   ---
      002   ???   ???   ???   ---   ---   ---
      004   ???   ???   ---   ---   ---   ---
      006   ???   ---   ---   ---   ---   ---
      008   ???   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

      CSC   001   002   004   006   008   010
      001   5.6   3.3   1.9   1.3   1.0   ---
      002   5.1   2.9   1.5   ---   ---   ---
      004   4.9   2.7   ---   ---   ---   ---
      006   4.8   ---   ---   ---   ---   ---
      008   4.7   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

      CSP   001   002   004   006   008   010
      001   5.6   5.7   5.6   5.7   5.7   ---
      002   5.1   4.8   4.8   ---   ---   ---
      004   4.9   4.8   ---   ---   ---   ---
      006   ???   ---   ---   ---   ---   ---
      008   ???   ---   ---   ---   ---   ---
      010   ---   ---   ---   ---   ---   ---

---
end
