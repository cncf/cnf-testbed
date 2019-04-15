#!/bin/bash
set -e
source ~/openrc

if [ "$(openstack server list | awk ""/test${1}/""'{print $4}')" == "test${1}" ] ; then
  float="$(openstack server list | awk ""/test${1}/""'{print $9}')"
  if [ ${float}  == "$(openstack floating ip list | awk ""/${float}/""'{print $4}')" ] ; then
    fip_id="$(openstack floating ip list | awk ""/${float}/""'{print $2}')"
    openstack floating ip delete ${fip_id}
  fi

  openstack  server delete test${1} --wait
fi

# TODO: do we need to tear down id_rsa folder and keypair?
