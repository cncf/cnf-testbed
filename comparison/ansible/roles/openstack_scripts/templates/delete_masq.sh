#!/bin/bash

if [[ $# == '0' ]]; then
  vlans=({% for key,value in packet_vlans.iteritems() %}{{value.vid}} {% endfor %})
  if [ -z "${vlans}" ]; then
  echo "usage: $0 {vlan-id}"
  exit 1
  fi
else
  vlans=$1
fi

subnet=${2:-10.20.30.0}
cidr=${3:-24}
gateway=${4:-10.20.30.1}

source ~/openrc

if iptables -t nat -C POSTROUTING -s ${subnet}/${cidr} -o bond0 -j MASQUERADE ; then
  iptables -t nat -D POSTROUTING -s ${subnet}/${cidr} -o bond0 -j MASQUERADE
fi

if grep '^net.ipv4.ip_forward=1' /etc/sysctl.conf -q ; then
  sed -i 's/net\.ipv4\.ip_forward=1/net.ipv4.ip_forward=0/g' /etc/sysctl.conf
  sed -i 's/net\.ipv6\.conf\.default\.forwarding=1/net.ipv6.conf.default.forwarding=0/g' /etc/sysctl.conf
  sysctl --system
fi


if [ "$( ip a | grep ${gateway} | awk '{print $2}' )" == "${gateway}/${cidr}" ]; then
  # ip l s down dev uplink
  ip a d $gateway/$cidr dev uplink
fi

if [ "$( openstack router list | awk '/routerext/ {print $4}' )" == "routerext" ] ;then
  for vlan in ${vlans[@]}; do
    if [  "$( openstack network list | grep vlan${vlan} | awk '{print $4}' )" == "vlan${vlan}" ] ;then
      openstack router remove subnet routerext subnet${vlan}
    fi
  done
  openstack router delete routerext
fi


if [ "$( openstack network list | awk '/netext/ {print $4}' )" == "netext" ] ;then
  openstack network delete netext
fi
