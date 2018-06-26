# Non-orchestrated Box-by-box comparison

- Host OS: Ubuntu 18.04
- VM hypervisor: KVM
- Container system: Docker

## Setup systems for comparison

Provision a Ubuntu 18.04 system

### Provision system for testing VNFs on KVM

Prereq: Ubuntu 18.04 LTS install

**Manual install**

Install Vagrant using debian packages from https://www.vagrantup.com/downloads.html

Find the 64bit debian package and download to the Ubuntu host system

**Script**

```
git clone git@github.com:cncf/cnfs.git
cd cnfs/comparison/box-by-box-kvm-docker
chmod +x install_kvm_prereqs.sh
./install_kvm_prereqs.sh
```

#### Test that vagrant + libvirt is working

Download a vagrant box with libvirt support and test that it works. Go to https://app.vagrantup.com/boxes/search?provider=libvirt to find one.

Then test:
```
mkdir -p /root/test1
pushd /root/test1
vagrant init centos/7
vagrant up
```

#### Install a test vagrant box with libvirt  provider support

For ubuntu 16.04 you can build your own (see packer directory) or use an existing one like elastic/ubuntu-16.04

```
vagrant init elastic/ubuntu-16.04-x86_64
```

### Provision system for testing CNFs on Docker

Prereq: Ubuntu 18.04 LTS install

**Manual**
Install Docker following the docker-ce install documentation https://docs.docker.com/install/linux/docker-ce/ubuntu/
 * Use the docker package repository
 
 
 **Script**
 ```
git clone git@github.com:cncf/cnfs.git
cd cnfs/comparison/box-by-box-kvm-docker
chmod +x install_docker_prereqs.sh
./install_docker_prereqs.sh
```

#### Test that Docker is working correctly

Test that docker is installed correctly with: `docker run hello-world`

### Clone comparison code

git clone git@github.com:cncf/cnfs.git
