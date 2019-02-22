#!/bin/bash
source ~/openrc
cat > /tmp/test${1}.cfg <<EOF
#!/bin/bash
passwd ubuntu <<EOL
ubuntu
ubuntu
EOL
EOF

FLAVOR=${2:-c0.small}

network=`openstack network list | awk '/vlan/ {print $4}' | head -1`
openstack  server create test${1} --flavor ${FLAVOR} --image xenial --nic net-id=${network} --config-drive True --user-data /tmp/test${1}.cfg


