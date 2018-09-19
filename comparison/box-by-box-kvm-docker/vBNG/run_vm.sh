#! /bin/bash

# Only run configuration is sockets are available
# Consider moving variables to top-level script (vBNG_vm_test.sh)
SOCKET_DIR="/var/run/vpp"
SOCKET_NAMES=( sock1.sock sock2.sock )
for sock in "${SOCKET_NAMES[@]}"; do
  if [ ! -e "${SOCKET_DIR}/${sock}" ]; then
    echo "ERROR - Socket ${SOCKET_DIR}/${sock} not found"
    exit 1
  else
    chown root:root ${SOCKET_DIR}/${sock}
  fi
done

cpus=( 14 16 18 )

input="$1"

mydir=$(dirname $0)

cd $mydir

if [ "$input" == "clean" ]; then
  vagrant destroy -f
  exit 0
fi

state=$(vagrant status | grep vBNG | awk '{print $2}')
if [ "$state" == "running" ]; then
  exit 0
fi

echo "Restarting VPP to prepare for VM interfaces"
service vpp restart
sleep 5

vagrant up

id=$(virsh list | grep vBNG_vBNG | awk '{print $1}')
if [ -z "$id" ]; then
  echo "ERROR - vBNG VM not running"
  exit 1
fi

virsh dumpxml --inactive --security-info $id > vBNG.xml

line=$(grep -HrIin "<serial type='pty'>" vBNG.xml | awk -F ':' '{print $2}')

sed -i "$((line-1))r Interfaces" vBNG.xml

virsh define vBNG.xml

vagrant reload

count=0
new_id=$(virsh list | grep vBNG_vBNG | awk '{print $1}')
for cpu in "${cpus[@]}"; do
  virsh vcpupin ${new_id} ${count} ${cpu}
  (( count++ ))
done

cmd="cp /vagrant/vnf_vbng_install.sh . && chmod +x vnf_vbng_install.sh && ./vnf_vbng_install.sh"
vagrant ssh -c "$cmd"
sleep 5

echo "Updating VPP configuration (rx-placement)"
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 0 worker 0
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 1 worker 1
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 2 worker 2
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 3 worker 3
vppctl set interface rx-placement VirtualEthernet0/0/0 queue 0 worker 4
vppctl set interface rx-placement VirtualEthernet0/0/0 queue 1 worker 5
vppctl set interface rx-placement VirtualEthernet0/0/1 queue 0 worker 6
vppctl set interface rx-placement VirtualEthernet0/0/1 queue 1 worker 7

echo ""
echo "## vBNG Started ##"
echo ""
