#!/bin/bash

# REPO_URL_BLOB=$(cat /opt/config/repo_url_blob.txt)
# REPO_URL_ARTIFACTS=$(cat /opt/config/repo_url_artifacts.txt)
# DEMO_ARTIFACTS_VERSION=$(cat /opt/config/demo_artifacts_version.txt)
# INSTALL_SCRIPT_VERSION=$(cat /opt/config/install_script_version.txt)
# CLOUD_ENV=$(cat /opt/config/cloud_env.txt)
#
# # Convert Network CIDR to Netmask
# cdr2mask () {
# 	# Number of args to shift, 255..255, first non-255 byte, zeroes
# 	set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
# 	[ $1 -gt 1 ] && shift $1 || shift
# 	echo ${1-0}.${2-0}.${3-0}.${4-0}
# }
#
# # OpenStack network configuration
# if [[ $CLOUD_ENV == "openstack" ]]
# then
# 	echo 127.0.0.1 $(hostname) >> /etc/hosts
#
# 	# Allow remote login as root
# 	mv /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bk
# 	cp /home/ubuntu/.ssh/authorized_keys /root/.ssh
#
# 	MTU=$(/sbin/ifconfig | grep MTU | sed 's/.*MTU://' | sed 's/ .*//' | sort -n | head -1)
#
# 	IP=$(cat /opt/config/cpe_public_net_ipaddr.txt)
# 	BITS=$(cat /opt/config/cpe_public_net_cidr.txt | cut -d"/" -f2)
# 	NETMASK=$(cdr2mask $BITS)
# 	echo "auto eth1" >> /etc/network/interfaces
# 	echo "iface eth1 inet static" >> /etc/network/interfaces
# 	echo "    address $IP" >> /etc/network/interfaces
# 	echo "    netmask $NETMASK" >> /etc/network/interfaces
# 	echo "    mtu $MTU" >> /etc/network/interfaces
#
# 	IP=$(cat /opt/config/oam_ipaddr.txt)
# 	BITS=$(cat /opt/config/oam_cidr.txt | cut -d"/" -f2)
# 	NETMASK=$(cdr2mask $BITS)
# 	echo "auto eth2" >> /etc/network/interfaces
# 	echo "iface eth2 inet static" >> /etc/network/interfaces
# 	echo "    address $IP" >> /etc/network/interfaces
# 	echo "    netmask $NETMASK" >> /etc/network/interfaces
# 	echo "    mtu $MTU" >> /etc/network/interfaces
#
# 	ifup eth1
# 	ifup eth2
# fi

# Download required dependencies
#echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu $(lsb_release -c -s) main" >>  /etc/apt/sources.list.d/java.list
#echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu $(lsb_release -c -s) main" >>  /etc/apt/sources.list.d/java.list

sudo add-apt-repository -s -y  ppa:openjdk-r/ppa
apt-get update
apt-get install --allow-unauthenticated -y wget openjdk-8-jdk bind9 bind9utils bind9-doc apt-transport-https ca-certificates kea-dhcp4-server g++ libcurl4-gnutls-dev libboost-dev kea-dev
sleep 1

# Download DNS and DHCP config files
cd /opt
#wget $REPO_URL_BLOB/org.onap.demo/vnfs/vcpe/$INSTALL_SCRIPT_VERSION/kea-dhcp4_no_hook.conf
#wget $REPO_URL_BLOB/org.onap.demo/vnfs/vcpe/$INSTALL_SCRIPT_VERSION/v_dns_init.sh
cp /vagrant/v_dns_init.sh .
#wget $REPO_URL_BLOB/org.onap.demo/vnfs/vcpe/$INSTALL_SCRIPT_VERSION/v_dns.sh

#mv kea-dhcp4_no_hook.conf /etc/kea/kea-dhcp4.conf
cp /vagrant/kea-dhcp4_no_hook.conf /etc/kea/kea-dhcp4.conf

chmod +x v_dns_init.sh
#chmod +x v_dns.sh
#mv v_dns.sh /etc/init.d
cp /vagrant/v_dns.sh /etc/init.d
chmod +x /etc/init.d/v_dns.sh
update-rc.d v_dns.sh defaults

# Install Bind
mkdir /etc/bind/zones
sed -i "s/OPTIONS=.*/OPTIONS=\"-4 -u bind\"/g" /etc/default/bind9

# # Rename network interface in openstack Ubuntu 16.04 images. Then, reboot the VM to pick up changes
# if [[ $CLOUD_ENV != "rackspace" ]]
# then
# 	sed -i "s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"/g" /etc/default/grub
# 	grub-mkconfig -o /boot/grub/grub.cfg
# 	sed -i "s/ens[0-9]*/eth0/g" /etc/network/interfaces.d/*.cfg
# 	sed -i "s/ens[0-9]*/eth0/g" /etc/udev/rules.d/70-persistent-net.rules
# 	echo 'network: {config: disabled}' >> /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
# 	echo "APT::Periodic::Unattended-Upgrade \"0\";" >> /etc/apt/apt.conf.d/10periodic
# 	reboot
# fi

./v_dns_init.sh
