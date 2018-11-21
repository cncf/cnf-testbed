#!/bin/bash

source ~/openrc
openstack network create --provider-segment {{vlans[0]}} --provider-network-type vlan --provider-physical-network physnet vlan{{vlans[0]}}
openstack network create --provider-segment {{vlans[1]}} --provider-network-type vlan --provider-physical-network physnet vlan{{vlans[1]}}
