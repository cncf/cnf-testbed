#! /bin/bash

source ~/open.rc
if [ ! -f xenial.img ]; then
curl https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img > xenial.img
fi
openstack  image create --container-format bare --disk-format qcow2 --min-disk 2 --min-ram 1000 --public --file xenial.img xenial
