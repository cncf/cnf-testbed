# Packer config to build a Ubuntu Vagrant image for the libvirt provider

Adjust ubuntu1604.json as desired then run

`packer build -var-file=ubuntu1604.json ubuntu-vagrant.json`
