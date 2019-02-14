#!/bin/bash
# source ~/openrc
#Set vEdge Script Branch
export BRANCH="master"
cat > /tmp/${3}.cfg <<EOF
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

if [[ $# == '0' ]]; then
    echo "usage: $0 {network-ids} {mac-addresses} {server-name}"
    exit 1
fi


IFS=',' read -r -a network <<< "$1"
IFS=',' read -r -a mac <<< "$2"

# get length of an array, excluding first element
arraylength=${#network[@]}

# Create first port automotically with the vm
for element in ${network[0]}
do
    openstack port create ${3} --network ${element} --mac-address ${mac[0]}
    openstack server create ${3} --flavor ${FLAVOR} --key-name oskey2 --image xenial --port ${3} --config-drive True --user-data /tmp/${3}.cfg
done

# Loop until server is running
until [ "$SERVER_STATUS" == "ACTIVE" ]; do
    SERVER_STATUS=$(openstack server show ${3} | awk '/status/ {print $4}')
done

# Add attatch remaining ports to the vm
for (( i=2; i<${arraylength}+1; i++ ));
do
  openstack port create ${3}${i} --network ${network[$i-1]} --mac-address ${mac[$i-1]}
  openstack server add port ${3} ${3}${i}
done
