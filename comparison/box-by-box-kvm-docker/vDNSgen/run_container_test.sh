#! /bin/bash

mydir=$(dirname $0)

cd $mydir

if [ "$1" ] ; then
  DNS_PACKET_RATE="$1"
elif [ -z "${DNS_PACKET_RATE}" ] ; then
  DNS_PACKET_RATE=10000
fi

echo "Using DNS Packet RATE $DNS_PACKET_RATE"

./build_container.sh

if [ -z "$(docker network ls | grep dns-net)" ]; then
  docker network create --subnet=40.30.20.0/24 dns-net
fi

if [ -z "$(docker ps | grep vDNSgen)" ]; then
  docker run --privileged --device=/dev/hugepages:/dev/hugepages -t -d --name vDNSgen vdnsgen /usr/bin/vpp -c /etc/vpp/startup.conf
  sleep 2
  docker network connect dns-net vDNSgen
  sleep 2
  #docker exec -e DNS_PACKET_RATE="${DNS_PACKET_RATE}" vDNSgen ./cnf_vdnsgen_init.sh
  docker exec vDNSgen ./cnf_vdnsgen_init.sh
  sleep 2
fi

sleep 2

echo "Starting DNS test script"
docker exec -e DNS_PACKET_RATE="${DNS_PACKET_RATE}" -it vDNSgen ./cnf_dns_test.sh $DNS_PACKET_RATE
