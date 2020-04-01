# CNF (Cloud native Network Function) Testbed

The CNCF CNF Testbed provides reference code and test cases for running networking code on Kubernetes and OpenStack using emerging cloud native technologies in the Telecom domain.

Status: The CNF Testbed is an initiative to create a repeatable, apples-to-apples testbed that telcos and telecoms vendors can use to evaluate how CNF architectures compare to more traditional VNF ones.

The initiative collaborates with the [CNCF Telecom User Group](https://github.com/cncf/telecom-user-group) to test and demonstrate different options.

Note: _Additional reference code and benchmarking tests will be added incrementally._


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

- Development platform for CNFs
- Comparing Virtual Network Functions (VNFs) to CNF implementations
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

 ### TUG + CNFs At [KubeCon + CloudNativeCon Europe 2020](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/)

Thursday, August 13 • 16:50 - 16:55 - [Build & Deploy a CNF in 5 Minutes](https://sched.co/Zeon)

Friday, August 14 • 12:00 - 12:35 - [Birds of a Feather: CNCF CI Working Group](https://sched.co/ZeuA)

Friday, August 14 • 14:35 - 15:10 - [Network Service Mesh to Address Cloud Native 5G Telco Networking Challenges](https://sched.co/Zelt)

Friday, August 14 • 15:30 - 16:05 - [CNF Testbed: Creating a Cloud Native User Plane for an Evolved Packet Core](https://sched.co/ZeuG)

Saturday, August 15 • 16:25 - 17:00 - [Enabling E2E Observability via Open Source in 5G Telco CNFs](https://sched.co/Zepo)

Saturday, August 15 • 16:25 - 17:55 - [Birds of a Feather: Telecom User Group](https://sched.co/Zevr)

 ### TUG + CNFs At Open Networking Summit & Edge NA 2020 
 - [TBA](https://events.linuxfoundation.org/open-networking-edge-summit-north-america/)
 
 ### TUG + CNFs At Open Networking Summit & Edge EU 2020 
- [TBA](https://events.linuxfoundation.org/open-networking-edge-summit-europe/)

 ### TUG + CNFs At KubeCon + CloudNativeCon NA 2020
- [TBA](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/)


## Past Events:

 ### TUG + CNFs At KubeCon + CloudNativeCon NA 2019

Wednesday, November 20 • 3:20pm - 3:55pm - [Birds of a Feather: Telecom User Group](https://sched.co/Uakt)

Thursday, November 21 • 4:25pm - 5:55pm - [Intro + Deep Dive: Cloud Native Network Function (CNF) Testbed](https://sched.co/UakA). [Watch the video:](https://youtu.be/_fD_4FuU_jg)

### TUG + CNFs At Open Networking Summit EU 2019

Monday, September 23 • 08:45 - 10:15 - [Tutorial: Take a Test Drive with the Cloud Native Network Function (CNF) Testbed - Sponsored by Cloud Native Computing Foundation (Pre-registration required)](https://sched.co/ScCA)

Monday, September 23 • 10:45 - 12:15 - [CNCF Telecom User Group Meeting](https://sched.co/Saoc)

Wednesday, September 25 • 14:35 - 15:05 - [Cloud Native Network Provisioning with Network Service Mesh in the CNF Testbed - Taylor Carpenter, Vulk Coop & Nikolay Nikolaev, VMware](https://sched.co/SYvw)

Wednesday, September 25 • 16:15 - 16:45 - [Panel Discussion: Embracing Cloud Native on the Path to 5G - Heather Kirksey, The Linux Foundation; Rabi Abdel, Vodafone; Lincoln Lavoie, UNH Interoperability Lab; Frederick Kautz, doc.ai; Taylor Carpenter, Vulk Coop](https://sched.co/SYwo)

### CNFs At KubeCon + CloudNativeCon China 2019

Tuesday, June 25 • 11:20 - 11:55am - [Intro + Deep Dive BoF: Telecom User Group and Cloud Native Network Functions (CNF) Testbed - Cheryl Hung, Dan Kohn, CNCF & Taylor Carpenter, Vulk Coop](https://sched.co/OBhN)


### CNFs At KubeCon + CloudNativeCon EU 2019

Monday, May 20 • 10:00 – 10:30am - [Cloud Native Network Services Day (Hosted by LF Networking): Exploring Cloud Native Network Solutions: A cross-project collaboration, Taylor Carpenter](https://www.linuxfoundation.org/calendar/kubecon-cloudnativecon-europe/)

Monday, May 20 • TBD - [Fd.io Mini-Summit](https://fdiominisummiteu19.sched.com/)

Thursday, May 23 • 11:05am - 12:30pm - [Intro + Deep Dive BoF: Telecom User Group and Cloud Native Network Functions (CNF) Testbed - Cheryl Hung, Dan Kohn, CNCF & Taylor Carpenter, Vulk Coop](https://sched.co/MSzj)


### CNFs At Open Networking Summit NA 2019

[Tutorial: Driving Telco Performance with the Cloud Native Network Function (CNF) Testbed - Sponsored by Cloud Native Computing Foundation (Pre-registration required)](https://sched.co/MnkD)

[Works on My Machine: How to Validate Performance of VNFs and CNFs in a Reproducible Testbed - W. Watson, Vulk Cooperative & Denver Williams](https://sched.co/LKUF)


### CNFs At KubeCon + CloudNativeCon North America 2018

Two Birds-of-a-Feather (BoF) sessions covered aspects of the CNF Testbed.

[Deep Dive: Using CNCF Cross-Cloud CI with CNFs – Denver Williams & Taylor Carpenter, Vulk Coop](https://kccna18.sched.com/event/Greb)

[Intro: Cloud Native Network Functions BoF - Dan Kohn, Cloud Native Computing Foundation](https://kccna18.sched.com/event/JCLS)
