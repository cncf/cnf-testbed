#! /bin/bash

mydir=$(dirname $0)

cd $mydir

if [ "$1" ] ; then
  DNS_PACKET_RATE="$1"
elif [ -z "${DNS_PACKET_RATE}" ] ; then
  DNS_PACKET_RATE=10000
fi

echo "Using DNS Packet RATE $DNS_PACKET_RATE"

vagrant up

sleep 2

vagrant ssh vDNSgen -- sudo ./vDNSgen/dns_test.sh $DNS_PACKET_RATE
