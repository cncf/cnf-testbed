#!/bin/bash
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

# Download and run vm install script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/shared/vEdge_vm_install.sh" -o /opt/vEdge_vm_install.sh
cd /opt
chmod +x vEdge_vm_install.sh
./vEdge_vm_install.sh



EOF

FLAVOR=${FLAVOR:-c0.small}
KEYPAIR=${KEYPAIR:-oskey}

if [ $# -lt 5 ]; then
    echo "ERROR: this script requires 3 parameters"
    echo "USAGE: $0 <server_name> <vlan_1_id> <vlan_2_id> <mac_1_address> <mac_2_address>"
    echo "NOTE: The script assumes networks are named vlan<vlan_id>"
    exit
fi

p1=$(openstack port create s${1}p1 --network vlan${2} --mac-address ${4} | awk '/ id / {print $4}')
p2=$(openstack port create s${1}p2 --network vlan${3} --mac-address ${5} | awk '/ id / {print $4}')
openstack server create ${1} --flavor c0.small --key-name ${KEYPAIR} --image xenial --nic port-id=${p1} --nic port-id=${p2} --config-drive True --user-data /tmp/${1}.cfg

rm /tmp/${1}.cfg
