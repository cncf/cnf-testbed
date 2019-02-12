#!/bin/bash
# source ~/openrc
#Set vEdge Script Branch
export BRANCH="master"
cat > /tmp/test${1}.cfg <<EOF
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
# ./vEdge_vm_install.sh



EOF

FLAVOR=${3:-c0.small}

network=`openstack network list | awk '/vlan/ {print $4}'`
openstack  server create test${1} --flavor ${FLAVOR} --key-name oskey --image xenial --nic net-id=${network} --config-drive True --user-data /tmp/test${1}.cfg
# openstack  server create test${1} --flavor ${FLAVOR} --key-name oskey --image xenial --nic net-id=7fef025c-8d0e-4fd7-82f0-45f6d3cbb9dd --nic net-id=a3fadec9-a4c8-4ee2-a3a0-b88c6576af77  --config-drive True --user-data /tmp/test${1}.cfg

