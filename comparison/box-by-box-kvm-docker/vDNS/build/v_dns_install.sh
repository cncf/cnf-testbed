#!/bin/bash

echo "export DEBIAN_FRONTEND=noninteractive" | tee -a /etc/profile

apt-get --no-install-recommends install -y sudo
sudo apt-get --no-install-recommends install -y software-properties-common python-software-properties
sudo add-apt-repository -s -y  ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get --no-install-recommends install -y --allow-unauthenticated wget openjdk-8-jdk bind9 bind9utils bind9-doc apt-transport-https ca-certificates kea-dhcp4-server g++ libcurl4-gnutls-dev libboost-dev kea-dev
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
cp /build/db_dnsdemo_onap_org /etc/bind/zones/db.dnsdemo.onap.org
cp /build/named.conf.options /etc/bind/
cp /build/named.conf.local /etc/bind/

echo "Starting DNS and DHCP services"
./v_dns_init.sh
