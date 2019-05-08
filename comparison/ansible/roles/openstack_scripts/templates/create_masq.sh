#!/bin/bash

if [ $# -lt 1 ]; then
  vlans=({% for key,value in packet_vlans.iteritems() %}{{value.vid}} {% endfor %})
  if [ -z "$vlans" ]; then
    echo "you need to pass three parameters:"
    echo " internal vlan id (e.g. 1044)"
    echo " opt: subnet start address (e.g. network address)"
    echo " opt: subnet cidr (e.g. 24)"
    echo " opt: gateway address (e.g. network address +1)"
    exit 1
  fi
fi

if [ -z "$1" ]; then
  vlan=${vlans[0]}
else
  vlan=${1}
fi
subnet=${2:-10.20.30.0}
cidr=${3:-24}
gateway=${4:-10.20.30.1}

source ~/openrc
if [ !  "$( openstack network list | awk '/netext/ {print $4}' )" == "netext" ] ;then
  openstack network create --external --provider-network-type flat --provider-physical-network flat netext
  openstack subnet create --network netext --subnet-range $subnet/$cidr --no-dhcp --gateway $gateway subnetext
fi

if [ ! "$( openstack router list | awk '/routerext/ {print $4}' )" == "routerext" ] ;then
  openstack router create routerext
  for vlan in ${vlans[@]}; do
    if [ ! "$( openstack network list | awk ""/vlan${vlan}/""'{print $4}' )" == "vlan${vlan}" ] ;then
      echo "vlan ${vlan} undefined in openstack network list. Did you run create_vlans.sh?"
      exit 1
    fi
    openstack router add subnet routerext subnet${vlan}
  done
  openstack router set routerext --external-gateway netext --enable-snat
fi

if [ ! "$( ip a | grep ${gateway} | awk '{print $2}' )" == "${gateway}/${cidr}" ]; then
  ip a a $gateway/$cidr dev uplink
  ip l s up dev uplink
fi

if ! grep '^net.ipv4.ip_forward=1' /etc/sysctl.conf -q ; then
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
  echo 'net.ipv6.conf.default.forwarding=1' >> /etc/sysctl.conf
  sysctl --system
fi

<<<<<<< 13b4635e41143d0b7617543567c7d1be6c11deea
if ! iptables -t nat -C POSTROUTING -s ${subnet}/${cidr} -o bond0 -j MASQUERADE ; then
=======
if [ "$(iptables-save -t nat | grep MASQUERADE > /dev/null 2>&1; echo $? )" == "1" ]; then
>>>>>>> Update for VXLan template support
  iptables -t nat -A POSTROUTING -s ${subnet}/${cidr} -o bond0 -j MASQUERADE
fi
