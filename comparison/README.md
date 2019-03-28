## CNF test comparison code

- ansible - common code for all tests belongs here
- baseline_nf_performance-csit - single and multichain tests on fd.io CSIT testbed-only (LF restricted access) [WIP]
  * KVM and Docker
- baseline_nf_performance-packet - single chain tests on Packet based csit-baseline_nf_performance test code [WIP]
  * KVM and Docker
- box-by-box-kvm-docker - comparison of CNF to VNFs on Docker and KVM (HISTORICAL) 
- doc - general reference documentation
- kubecon18-chained_nf_test - CNF to VNF comparison test cases for Kubecon Seattle 2018 Keynote
  * OpenStack and K8s
  * Everything (sans ansible) belongs here for the Keynote comparison
  * _NOTE_: directory may be renamed before Dec 10th, 2018
