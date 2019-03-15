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
if [ ! -f /root/.ssh/id_rsa ] ;then
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
openstack keypair create oskey --public-key ~/.ssh/id_rsa.pub
fi

if [ ! "$(openstack server list | grep test${1} | awk '{print $4}')" == "test${1}" ] ; then
network=`openstack network list | awk '/vlan/ {print $4}' | head -1`
openstack  server create test${1} --flavor ${FLAVOR} --image xenial --nic net-id=${network} --config-drive True --user-data /tmp/test${1}.cfg --key-name oskey --wait
fi

if [ "$(openstack network list | awk '/netext/ {print $4}')" == "netext" ] ; then
float=$(openstack floating ip create netext | awk '/floating_ip_address/ {print $4}')
port_ip=$(openstack server list | grep test${1} | awk '{print $8}' | cut -d, -f1 | cut -d= -f2 )
port_id=$(openstack port list | grep ${port_ip} | awk '{print $2}')

openstack floating ip set --port=${port_id} ${float}
echo Log into your server with:
echo   ubuntu@${float}
fi

