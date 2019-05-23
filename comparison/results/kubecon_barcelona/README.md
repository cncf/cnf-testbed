## Summary of results

* All benchmarks are done using VPP v19.04 in both host vSwitch and CNF.
* All tests are done using Docker directly. __K8s is not used!__
* The host vSwitch is running in a container.
* All tests are using 3 chains of 2 CNFs (6 CNFs total)
* Results are an average based on 3 iterations
  - Tests run: PDR, NDR and MRR (10Gbps)
* Two CNF configurations have been used
  - CSP "Pipeline": CNFs in each chain are interconnected directly using memif interfaces
  - CSC "Snake": CNFs always connect through the host vSwitch using memif interfaces
* Each setup has been benchmarked with both privileged and unprivileged CNFs

### CSP "Snake" results
Privileged CNFs:
* PDR: 6.05 Gbps (9.01 Mpps)
* NDR: 6.05 Gbps (9.01 Mpps)
* MRR: 6.72 Gbps (9.99 Mpps)

Unprivileged CNFs:
* PDR: 5.58 Gbps (8.30 Mpps)
* NDR: 5.57 Gbps (8.29 Mpps)
* MRR: 5.38 Gbps (8.00 Mpps)

### CSC "Pipeline" results
Privileged CNFs:
* PDR: 4.18 Gbps (6.22 Mpps)
* NDR: 4.16 Gbps (6.19 Mpps)
* MRR: 4.48 Gbps (6.67 Mpps)

Unprivileged CNFs:
* PDR: 3.57 Gbps (5.32 Mpps)
* NDR: 3.57 Gbps (5.31 Mpps)
* MRR: 3.63 Gbps (5.40 Mpps)
