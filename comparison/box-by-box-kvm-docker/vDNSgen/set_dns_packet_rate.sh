#!/bin/bash

if [ -z "$1" ] ; then
  echo "$0 <packet rate>"
  exit 1
fi

DNS_PACKET_RATE=$1

SUDO=$(which sudo)
echo "Updating rate to $DNS_PACKET_RATE"
$SUDO sed -i "s/^\(\s*rate\s\)*[0-9]*$/\1${DNS_PACKET_RATE}/" /opt/dns_streams/stream_dns*

$SUDO systemctl restart vpp
sleep 1

for stream in `ls /opt/dns_streams/stream_dns*` ; do
  $SUDO vppctl exec $stream
done
sleep 1

