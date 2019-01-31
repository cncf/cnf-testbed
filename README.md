# CNFs - Cloud-native Network Functions

The CNCF CNF Testbed provides reference code and test comparisons of Cloud-native Network Functions. 


## What is the CNCF CNF Testbed?

The CNF Testbed will help facilitate the transition in the NFV world from virtualized hardware running network functions to lightweight, network functions following cloud-native methodologies running on Kubernetes in public, private, or hybrid clouds. 

The reference code and comparisons from the CNF Testbed support the claim that CNFs orchestrated by Kubernetes will provide 3 major benefits to service providers: 

1. Cost savings (capex/opex)
1. Improved resiliency
1. Higher development velocity

Note that the CNF Testbed is still in the prototype stage. Additional reference code and benchmarking tests will be added incrementally.

The ideal outcome of the CNF Testbed is that a third party developer can run the provided CNF reference code/benchmarking tests with an API key and a couple of CLI commands. Furthermore, a developer can re-use some or all of the software in their own environment with minimal, or at least isolated modifications.


## CNF Testbed goals

**The CNF Testbed includes the following high-level goals:**

- Comparing Virtual Network Functions (VNFs) vs. Cloud-native Network Functions (CNFs)
- Providing easily reproducible test cases and use cases
- Providing Helm Charts for CNFs
- Using 100% open source software
- Supporting automated deployment from bare-metal up
- Building the software in working, composable parts 


## Let’s see some of the test cases

So far the project has been focused on provisioning the infrastructure to support data plane CNF test cases that would be of interest to a service provider. This includes building up from minimal, single NFs running on KVM and Docker to OpenStack and K8s.

**Current Test Cases:** 

- [CNF chained nf test code](https://github.com/cncf/cnfs/blob/master/comparison/kubecon18-chained_nf_test/README.md)
- [Box-by-box KVM and Docker](https://github.com/cncf/cnfs/tree/master/comparison/box-by-box-kvm-docker)
- [Baseline NF Performance on Packet](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet)
- [Baseline NF Performance on CSIT](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-csit)


## Getting Involved and Contributing

Are you interested in contributing to CNFs? We, the maintainers and community,
would love your suggestions, contributions, and help! The
maintainers can be contacted at any time to learn more about how to get
involved.

**What this means:**

__Issues__
* Point out issues that are duplicates, out of date, etc.

__Pull Requests__
* Read and review the code. Leave comments, questions, and critiques.
* Download, compile, and run the code and make sure the tests pass.
  - Also verify that the test cases follow best architectural patterns and include tests.


## CNFs At KubeCon + CloudNativeCon North America 2018

Several talks and demos targeting different experience are scheduled for KubeCon North America 2018. Please join us to get more insights about Cloud-native Network Functions (CNFs), the current state of the 


and test cases.

**Monday, December 10**
 - 11:40am - 12:00pm - [CNFs in Switzerland: Reproducible Performance Testing in a Neutral Environment - Taylor Carpenter, Vulk Coop](https://fdiominisummitatkccncnortha2018.sched.com/event/IGg6/cnfs-in-switzerland-reproducible-performance-testing-in-a-neutral-environment)

**Wednesday, December 12** 

 - 10:50am - 11:25am - [Deep Dive: Using CNCF Cross-Cloud CI with CNFs – Denver Williams & Taylor Carpenter, Vulk Coop](https://kccna18.sched.com/event/Greb)

 - 2:35pm - 3:10pm - [Intro: Cloud Native Network Functions BoF - Dan Kohn, Cloud Native Computing Foundation](https://kccna18.sched.com/event/JCLS)
