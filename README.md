# Cloud native Network Function (CNF) Testbed

The CNCF CNF Testbed provides reference code and test cases for running the same networking code packaged as containers (Cloud native Network Functions or CNFs) on Kubernetes and as virtual machines (Virtual Network Functions or VNFs) on OpenStack.

Status: The CNF Testbed is *not* a CNCF-hosted [project](https://www.cncf.io/projects/). Instead, it is an initiative to create a repeatable, apples-to-apples testbed that telcos and telecoms vendors can use to evaluate how CNF architectures compare to more traditional VNF ones.

The initiative collaborates with the [CNCF Telecom User Group](https://github.com/cncf/telecom-user-group) to test and demonstrate differents options.

Note: _The CNF Testbed is still in the prototype stage. Additional reference code and benchmarking tests will be added incrementally._


## CNF Testbed purpose and ideal outcome?

The CNF Testbed will help facilitate the transition in the NFV world from virtualized hardware running network functions to lightweight, network functions following cloud-native methodologies running on Kubernetes in public, private, or hybrid clouds. 

The reference code and comparisons from the CNF Testbed support the claim that CNFs orchestrated by Kubernetes will provide 3 major benefits to service providers: 

1. Cost savings (capex/opex)
1. Improved resiliency
1. Higher development velocity

The ideal outcome of the CNF Testbed is that a third party developer can run the provided CNF reference code/benchmarking tests with an API key and a couple of CLI commands. Furthermore, a developer can re-use some or all of the software in their own environment with minimal, or at least isolated modifications.

### Background info

Please review this slide [deck](https://docs.google.com/presentation/u/1/d/1nsPINvxQwZZR_7E4mAzr-50eFCBhbCHsmik6DI_yFA0/).

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

**Events and recurring testing:** 

- _(recurring)_ [Baseline NF Performance on Packet](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-packet)
- _(recurring)_ [Baseline NF Performance on CSIT](https://github.com/cncf/cnfs/tree/master/comparison/baseline_nf_performance-csit)
- Mellanox Chained IP Routers: OpenStack & K8s
- [Kubecon NA 2019 Chained IP Routers](https://github.com/cncf/cnfs/blob/master/comparison/kubecon18-chained_nf_test/README.md)
- [Box-by-box KVM and Docker](https://github.com/cncf/cnfs/tree/master/comparison/box-by-box-kvm-docker)




## Getting Involved and Contributing

Are you interested in contributing to CNFs? We, the maintainers and community,
would love your suggestions, contributions, and help! Please email info@cncf.io or open an issue or pull request if you have questions or suggestions.

**What this means:**

__Issues__
* Point out issues that are duplicates, out of date, etc.

__Pull Requests__
* Read and review the code. Leave comments, questions, and critiques.
* Download, compile, and run the code and make sure the tests pass.
  - Also verify that the test cases follow best architectural patterns and include tests.

## Meeting Time

The CNF Testbed is discussed as part of the CNCF Telecom User Group. Please see https://github.com/cncf/telecom-user-group#meeting-time.

## Meeting Minutes

Upcoming and past meeting agenda/notes are available [here](https://tinyurl.com/cncf-cnf-testbed-bof).

## Slack

[https://slack.cncf.io/](https://slack.cncf.io/)
- #tug (Telecom User Group)
- #cnf-testbed (Testing and R&D) 
- #nsm (Network Service Mesh)


## Upcoming Events:

### CNFs At KubeCon + CloudNativeCon China 2019

TBD


### CNFs At KubeCon + CloudNativeCon EU 2019

Monday, May 20 • 10:00 – 10:30am - [Cloud Native Network Services Day (Hosted by LF Networking): Exploring Cloud Native Network Solutions: A cross-project collaboration, Taylor Carpenter](https://www.linuxfoundation.org/calendar/kubecon-cloudnativecon-europe/)

Monday, May 20 • TBD - [Fd.io Mini-Summit](https://fdiominisummiteu19.sched.com/)

Thursday, May 23 • 11:05am - 12:30pm - [Intro + Deep Dive BoF: Telecom User Group and Cloud Native Network Functions (CNF) Testbed - Cheryl Hung, Dan Kohn, CNCF & Taylor Carpenter, Vulk Coop](https://sched.co/MSzj)


### CNFs At KubeCon + CloudNativeCon China 2019

Tuesday, June 25 • 11:20 - 11:55am - [Intro + Deep Dive BoF: Telecom User Group and Cloud Native Network Functions (CNF) Testbed - Cheryl Hung, Dan Kohn, CNCF & Taylor Carpenter, Vulk Coop](https://sched.co/OBhN)


## Past Events:

### CNFs At Open Networking Summit NA 2019

[Tutorial: Driving Telco Performance with the Cloud Native Network Function (CNF) Testbed - Sponsored by Cloud Native Computing Foundation (Pre-registration required)](https://sched.co/MnkD)

[Works on My Machine: How to Validate Performance of VNFs and CNFs in a Reproducible Testbed - W. Watson, Vulk Cooperative & Denver Williams](https://sched.co/LKUF)

### CNFs At KubeCon + CloudNativeCon North America 2018

Two Birds-of-a-Feather (BoF) sessions covered aspects of the CNF Testbed.

[Deep Dive: Using CNCF Cross-Cloud CI with CNFs – Denver Williams & Taylor Carpenter, Vulk Coop](https://kccna18.sched.com/event/Greb)

[Intro: Cloud Native Network Functions BoF - Dan Kohn, Cloud Native Computing Foundation](https://kccna18.sched.com/event/JCLS)
