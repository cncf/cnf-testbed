#!/bin/bash

CHAIN="1"
NODE="1"
NODES="1"

# source ~/openrc
#Set vEdge Script Branch
export BRANCH="master"
cat > /tmp/${1}.cfg <<EOF
#!/bin/bash
passwd ubuntu <<EOL
ubuntu
ubuntu
EOL
cat >/etc/resolv.conf <<EOL
nameserver 8.8.8.8
EOL

# Download igb_uio.ko kernal module
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/base_image/shared/igb_uio.ko" -o /opt/igb_uio.ko

# Download and run vm build script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/base_image/vedge_vm_build.sh" -o /opt/vedge_vm_build.sh
cd /opt
chmod +x vedge_vm_build.sh
./vedge_vm_build.sh

# Download the dpdk-devbind script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/shared/dpdk-devbind.py" -o /opt/dpdk-devbind.py
cd /opt
chmod +x dpdk-devbind.py

ifdown ens3 ens4

# Download and run vm install script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/shared/vEdge_vm_install.sh" -o /opt/vEdge_vm_install.sh
cd /opt
chmod +x vEdge_vm_install.sh
./vEdge_vm_install.sh $CHAIN $NODE $NODES

sed -i -e '/auto ens3/,+6d' /etc/network/interfaces.d/50-cloud-init.cfg
sed -i -e '/auto ens4/,+6d' /etc/network/interfaces.d/50-cloud-init.cfg

reboot

EOF

FLAVOR=${FLAVOR:-c0.small}
KEYPAIR=${KEYPAIR:-oskey}

if [ $# -lt 4 ]; then
    echo "ERROR: this script requires 3 parameters"
    echo "USAGE: $0 <server_name> <vlan_1_id> <vlan_2_id> <EXT_vlan_3_id>"
    echo "NOTE: The script assumes networks are named vlan<vlan_id>"
    exit
fi

p1=$(openstack port create s${1}p1 --network vlan${2} | awk '/ id / {print $4}')
p2=$(openstack port create s${1}p2 --network vlan${3} | awk '/ id / {print $4}')
p3=$(openstack port create s${1}p3 --network ext${4} | awk '/ id / {print $4}')
openstack server create ${1} --flavor vnf.3c --key-name ${KEYPAIR} --image xenial --nic port-id=${p1} --nic port-id=${p2} --nic port-id=${p3} --config-drive True --user-data /tmp/${1}.cfg

rm /tmp/${1}.cfg
