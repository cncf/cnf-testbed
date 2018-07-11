#! /bin/bash

if [ -z "$(docker network ls | grep dns-net)" ]; then
  docker network create --subnet=40.30.20.0/24 dns-net
fi

if [ -z "$(docker image list | grep vdnsgen)" ]; then
  docker build -t vdnsgen .
fi

if [ -z "$(docker ps | grep vDNSgen)" ]; then
  docker run --privileged --device=/dev/hugepages:/dev/hugepages -t -d --name vDNSgen vdnsgen /usr/bin/vpp -c /etc/vpp/startup.conf
  sleep 2
  docker network connect dns-net vDNSgen
  sleep 2
  docker exec vDNSgen ./cnf_vdnsgen_init.sh
  sleep 2
fi

sleep 2

docker exec -it vDNSgen ./cnf_dns_test.sh
