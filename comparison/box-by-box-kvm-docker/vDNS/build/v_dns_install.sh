#!/bin/bash

sudo add-apt-repository -s -y  ppa:openjdk-r/ppa
apt-get update
apt-get install --allow-unauthenticated -y wget openjdk-8-jdk bind9 bind9utils bind9-doc apt-transport-https ca-certificates kea-dhcp4-server g++ libcurl4-gnutls-dev libboost-dev kea-dev
sleep 1

# Download DNS and DHCP config files
cd /opt
cp /build/v_dns_init.sh .
cp /build/kea-dhcp4_no_hook.conf /etc/kea/kea-dhcp4.conf

chmod +x v_dns_init.sh

cp /build/v_dns.sh /etc/init.d
chmod +x /etc/init.d/v_dns.sh
update-rc.d v_dns.sh defaults

# Install Bind
mkdir /etc/bind/zones
sed -i "s/OPTIONS=.*/OPTIONS=\"-4 -u bind\"/g" /etc/default/bind9

echo "Starting DNS and DHCP services"
./v_dns_init.sh
