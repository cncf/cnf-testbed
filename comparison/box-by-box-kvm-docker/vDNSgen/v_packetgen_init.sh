#!/bin/bash

# Start VPP
sudo systemctl start vpp
sleep 1

# Compute the network CIDR from the Netmask
mask2cidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognized"; exit 1
        esac
    done
    echo "$nbits"
}

#IPADDR1_MASK=$(ifconfig eth1 | grep "Mask" | awk '{print $4}' | awk -F ":" '{print $2}')
#IPADDR1_CIDR=$(mask2cidr $IPADDR1_MASK)

# Configure VPP for vPacketGenerator
#IPADDR1=$(ifconfig eth1 | grep "inet addr" | tr -s ' ' | cut -d' ' -f3 | cut -d':' -f2)
#HWADDR1=$(ifconfig eth1 | grep HWaddr | tr -s ' ' | cut -d' ' -f5)
#FAKE_HWADDR1=$(echo -n 00; dd bs=1 count=5 if=/dev/urandom 2>/dev/null | hexdump -v -e '/1 ":%02X"')
#TAPCLI0_IPADDR=40.30.20.91
IPADDR1=40.30.20.90
IPADDR1_CIDR=24
PG_IPADDR=40.30.20.92
#VLB_IPADDR=$(cat /opt/config/vlb_ipaddr.txt)
DST_IPADDR=40.30.20.110
DST_MAC=aa:bb:cc:dd:ee:ff
#VLB_MAC=$(cat /opt/config/vlb_mac.txt)
GW=$(route -n | grep "^0.0.0.0" | awk '{print $2}')

#sudo ifconfig eth1 down
#sudo ifconfig eth1 hw ether $FAKE_HWADDR1
#sudo ip addr flush dev eth1
#sudo ifconfig eth1 up
#sudo vppctl tap connect tap-0 hwaddr $HWADDR1
#sudo vppctl set int ip address tapcli-0 $IPADDR1"/"$IPADDR1_CIDR
#sudo vppctl set int ip address tapcli-0 $TAPCLI0_IPADDR"/"$IPADDR1_CIDR
#sudo vppctl set int state tapcli-0 up
#sudo brctl addbr br0
#sudo brctl addif br0 tap-0
#sudo brctl addif br0 eth1
#sudo ifconfig br0 up
sudo vppctl ip route add 0.0.0.0/0 via $GW
sleep 1

# Set br0 with public IP and valid MAC so that Linux will have public network access
#sudo ifconfig br0 hw ether $HWADDR1
#sudo ifconfig br0 $IPADDR1 netmask $IPADDR1_MASK
#sudo route add default gw $GW
#sleep 1
sudo vppctl set ip arp GigabitEthernet0/6/0 $DST_IPADDR $DST_MAC

# Install packet streams

#sudo sed -i 's/rate 10/rate 10000/g' /opt/dns_streams/stream_dns*

sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns1
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns2
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns3
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns4
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns5
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns6
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns7
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns8
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns9
sudo sed -i -e "0,/UDP/ s/UDP:.*/UDP: "$IPADDR1" -> "$DST_IPADDR"/" /opt/dns_streams/stream_dns10

#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns1
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns2
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns3
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns4
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns5
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns6
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns7
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns8
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns9
#sudo sed -i -e "s/.*-> 53.*/    UDP: $RANDOM -> 53/" /opt/dns_streams/stream_dns10

sudo vppctl exec /opt/dns_streams/stream_dns1
sudo vppctl exec /opt/dns_streams/stream_dns2
sudo vppctl exec /opt/dns_streams/stream_dns3
sudo vppctl exec /opt/dns_streams/stream_dns4
sudo vppctl exec /opt/dns_streams/stream_dns5
sudo vppctl exec /opt/dns_streams/stream_dns6
sudo vppctl exec /opt/dns_streams/stream_dns7
sudo vppctl exec /opt/dns_streams/stream_dns8
sudo vppctl exec /opt/dns_streams/stream_dns9
sudo vppctl exec /opt/dns_streams/stream_dns10

sleep 1
#sudo vppctl set int ip address pg0 $PG_IPADDR"/"$IPADDR1_CIDR
sleep 1

# Seems this is necessary twice to open connection ??
#sudo vppctl set interface ip address del tapcli-0 all
#sudo vppctl set interface ip address tapcli-0 $TAPCLI0_IPADDR"/"$IPADDR1_CIDR
#sudo vppctl set ip arp tapcli-0 $DST_IPADDR $DST_MAC

echo "Exiting scrpit before running 'run_streams_dns.sh'"
exit 0

chmod +x run_streams_dns.sh
./run_streams_dns.sh &>/dev/null &disown
