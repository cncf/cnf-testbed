#!/bin/bash

if [ $# -lt 3 ]; then
  echo "ERROR: this script requires a minimum of 3 parameters"
  echo "USAGE: $0 <server_name> <vlan_1_id> <vlan_2_id> {mac_1} {mac_2}"
  echo "NOTE: The script assumes networks are named vlan<vlan_id>"
  echo "If MAC addresses are not passed on the command line, MACs will be generated"
  exit
fi

source ~/openrc
cat > /tmp/${1}.cfg <<EOF
#!/bin/bash
passwd ubuntu <<EOL
ubuntu
ubuntu
EOL
EOF
if [ -z ${4} ]; then
m1=$(echo fa:17:b4:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10])
else
m1=${4}
fi

if [ -z ${5} ]; then
m2=$(echo fa:17:b5:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10])
else
m2=${5}
fi

p1=$(openstack port create s${1}p1 --network vlan${2} --mac-address ${m1} | awk '/ id / {print $4}')
p2=$(openstack port create s${1}p2 --network vlan${3} --mac-address ${m2} | awk '/ id / {print $4}')
openstack server create ${1} --flavor c0.small --image xenial --nic port-id=${p1} --nic port-id=${p2} --config-drive True --user-data /tmp/${1}.cfg

rm /tmp/${1}.cfg
