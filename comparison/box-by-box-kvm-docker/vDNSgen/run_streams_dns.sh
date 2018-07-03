#!/bin/bash

#Disable all the running streams
sudo vppctl packet-gen disable

#Initial configuration: run only two streams
sudo vppctl packet-gen enable-stream dns1
sudo vppctl packet-gen enable-stream dns2

#sleep 60
sleep 120
sudo vppctl packet-gen disable
exit 0

#Rehash port numbers and re-run five streams every minute
while true; do
	sudo vppctl packet-gen disable
	sudo vppctl pac del dns1
	sudo vppctl pac del dns2
	sudo vppctl pac del dns3
	sudo vppctl pac del dns4
	sudo vppctl pac del dns5

	#Update destination (vLB) IP
	DST_IPADDR=40.30.20.110
	IPADDR1=40.30.20.91
	sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns1
	sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns2
	sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns3
	sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns4
	sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns5

	#Update source ports (make them random)
	sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns1
	sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns2
	sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns3
	sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns4
	sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns5

	sudo vppctl exec /opt/dns_streams/stream_dns1
	sudo vppctl exec /opt/dns_streams/stream_dns2
	sudo vppctl exec /opt/dns_streams/stream_dns3
	sudo vppctl exec /opt/dns_streams/stream_dns4
	sudo vppctl exec /opt/dns_streams/stream_dns5

	#Resume stream execution
	sudo vppctl packet-gen enable-stream dns1
	sudo vppctl packet-gen enable-stream dns2
	sudo vppctl packet-gen enable-stream dns3
	sudo vppctl packet-gen enable-stream dns4
	sudo vppctl packet-gen enable-stream dns5

	sleep 60
done
