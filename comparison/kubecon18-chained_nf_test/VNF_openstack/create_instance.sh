#!/bin/bash
source ~/openrc
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

# Download and run install script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/base_image/vedge_vm_build.sh" -o /opt/vedge_vm_build.sh
cd /opt
chmod +x vedge_vm_build.sh
./vedge_vm_build.sh

EOF

FLAVOR=${2:-c0.small}

network=`openstack network list | awk '/vlan/ {print $4}'`
openstack  server create test${1} --flavor ${FLAVOR} --key-name oskey --image xenial --nic net-id=${network} --config-drive True --user-data /tmp/test${1}.cfg
