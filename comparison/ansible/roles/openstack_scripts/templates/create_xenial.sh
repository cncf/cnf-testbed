#! /bin/bash
source ~/openrc
if [ ! -f xenial.img ]; then
  curl https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img > xenial.img
fi
if [[ ! $(openstack image list | grep xenial | wc -l) -ge 1 ]]; then
  openstack  image create --container-format bare --disk-format qcow2 --min-disk 2 --min-ram 1000 --public --file xenial.img xenial
fi
