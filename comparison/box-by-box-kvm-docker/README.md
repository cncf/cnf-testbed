# Non-orchestrated Box-by-box comparison

- Host OS: Ubuntu 18.04
- VM hypervisor: KVM
- Container system: Docker

## Setup systems for comparison

Provision a Ubuntu 18.04 system

### Provision system for testing VNFs on KVM

Prereq: Ubuntu 18.04 LTS install

Install Vagrant using debian packages from https://www.vagrantup.com/downloads.html

Find the 64bit debian package and download to the Ubuntu host system

#### Test that vagrant + libvirt is working

Download a vagrant box with libvirt support and test that it works. Go to https://app.vagrantup.com/boxes/search?provider=libvirt to find one.

Then test:
```
mkdir -p /root/test1
pushd /root/test1
vagrant init centos/7
vagrant up
```

### Provision system for testing CNFs on Docker

Prereq: Ubuntu 18.04 LTS install

Install Docker following the docker-ce install documentation https://docs.docker.com/install/linux/docker-ce/ubuntu/
 * Use the docker package repository

Test that docker is installed correctly with: `docker run hello-world`

### Clone comparison code

git clone git@github.com:cncf/cnfs.git
