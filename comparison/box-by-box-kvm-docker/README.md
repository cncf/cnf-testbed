# Non-orchestrated Box-by-box comparison

- Host OS: Ubuntu 18.04
- VM hypervisor: KVM
- Container system: Docker

## Setup systems for comparison

### Provision system for testing CNFs on Docker

Provision a Ubuntu 18.04 system

Install Docker following the docker-ce install documentation https://docs.docker.com/install/linux/docker-ce/ubuntu/
 * Use the docker package repository

Test that docker is installed correctly with: `docker run hello-world`

### Clone comparison code

git clone git@github.com:cncf/cnfs.git
