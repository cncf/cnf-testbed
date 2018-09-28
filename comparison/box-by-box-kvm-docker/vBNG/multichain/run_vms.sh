#! /bin/bash

clear_tmp_files() {
  config_files=( vEdge_Interfaces.tmp vEdge.xml )
  for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
      rm $file
    fi
  done
}

update_vpp_config() {
  if ! cmp -s "/etc/vpp/setup.gate" "vEdge_multichain_vpp.conf" ; then
    echo "Updating VPP configuration"
    cp vEdge_multichain_vpp.conf /etc/vpp/setup.gate
    service vpp restart
    sleep 5
  fi
}

create_interface_list() {
  # Args: <chain number>
  if [[ "${1}" == "1" ]]; then
    mac1=52:54:00:00:00:aa
    mac2=52:54:00:00:01:bb
  elif [[ "${1}" == "${chains}" ]]; then
    mac1=52:54:00:00:0${1}:aa
    mac2=52:54:00:00:00:bb
  else
    mac1=52:54:00:00:0${1}:aa
    mac2=52:54:00:00:0${1}:bb
  fi
  bash -c "cat > vEdge_Interfaces.tmp" <<EOF
    <interface type='vhostuser'>
      <mac address='${mac1}'/>
      <source type='unix' path='/var/run/vpp/sock$((${1} * 2 - 1)).sock' mode='client'/>
      <model type='virtio'/>
      <driver queues='2'/>
    </interface>
    <interface type='vhostuser'>
      <mac address='${mac2}'/>
      <source type='unix' path='/var/run/vpp/sock$((${1} * 2)).sock' mode='client'/>
      <model type='virtio'/>
      <driver queues='2'/>
    </interface>
EOF
}

chains="$1"
cleanup="$2"

## Input validation ##
if [[ -n ${chains//[0-9]/} ]] || [[ "$chains" -le "1" ]] ; then
  echo "ERROR: Chains must be integer value higher than 1"
  echo "  Provided: $0 $1 $2"
  echo "Usage: $0 <Chains> [clean]"
  exit 1
fi

# Only run configuration is sockets are available
# Consider moving variables to top-level script (vBNG_vm_test.sh)
#SOCKET_DIR="/var/run/vpp"
#SOCKET_NAMES=( sock1.sock sock2.sock )
#for sock in "${SOCKET_NAMES[@]}"; do
#  if [ ! -e "${SOCKET_DIR}/${sock}" ]; then
#    echo "ERROR - Socket ${SOCKET_DIR}/${sock} not found"
#    exit 1
#  else
#    chown root:root ${SOCKET_DIR}/${sock}
#  fi
#done

VLANs="1070 1064"
cpus=( 10 12 40 38 14 42 16 18 46 44 20 48 22 24 52 50 26 54 )

mydir=$(dirname $0)

cd $mydir

if [ "$cleanup" == "clean" ]; then
  for chain in $(seq 1 $chains); do
    vagrant destroy v${chain}Edge -f
  done
  exit 0
fi

exit_flag=0
running_vms="Active VMs: "
echo "Checking for existing VMs.."
for chain in $(seq 1 $chains); do
  state=$(vagrant status | grep v${chain}Edge | awk '{print $2}')
  if [ "$state" == "running" ]; then
    running_vms="${running_vms} v${chain}Edge "
    exit_flag=1
  fi
  echo ".."
done

if [[ "${exit_flag}" == "1" ]]; then
  echo "One or more VMs are running, please remove before running script"
  echo "  ${running_vms}"
  echo "  Usage: $0 <Chains> [clean]"
  exit 1
fi  

echo "Updating & Restarting VPP to prepare for VM interfaces"
./create_vpp_config.sh ${chains} ${VLANs}
update_vpp_config

./create_vagrantfile.sh ${chains}

vagrant up

clear_tmp_files

for id in $(virsh list | grep multichain | grep running | awk '{print $1}'); do
  echo "Virsh ID: $id"
  virsh dumpxml --inactive --security-info $id > vEdge.xml
  # Below we collect vagrant_id, since instances might not spawn in correct order
  vagrant_id=$(cat vEdge.xml | grep "<name>" | sed 's/[^0-9]*//g')
  echo "Vagrant ID: $vagrant_id"
  line=$(grep -HrIin "<serial type='pty'>" vEdge.xml | awk -F ':' '{print $2}')
  create_interface_list $vagrant_id
  cat vEdge_Interfaces.tmp
  sed -i "$((line-1))r vEdge_Interfaces.tmp" vEdge.xml
  sleep 1
  virsh define vEdge.xml
done

vagrant reload

core_count=0
for id in $(virsh list | grep multichain | grep running | awk '{print $1}'); do
  echo "CPU Pinning v$(virsh dumpxml $id | grep '<name>' | sed 's/[^0-9]*//g')Edge"
  for core in {0..2}; do
    virsh vcpupin ${id} ${core} ${cpus[${core_count}]}
    (( core_count++ ))
  done
done

for cid in $(seq 1 ${chains}); do
  cmd="cp /vagrant/* . && chmod +x vnf_vbng_install.sh && ./vnf_vbng_install.sh ${cid} ${chains}"
  vagrant ssh v${cid}Edge -c "$cmd"
done
sleep 5

echo "Updating VPP configuration (rx-placement)"
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 0 worker 0
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 1 worker 1
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 2 worker 2
vppctl set interface rx-placement TwentyFiveGigabitEthernet5e/0/1 queue 3 worker 3

worker=4
for vEth in $(seq 0 $(($chains * 2 - 1))); do
  vppctl set interface rx-placement VirtualEthernet0/0/${vEth} queue 0 worker ${worker}
  echo "vppctl set interface rx-placement VirtualEthernet0/0/${vEth} queue 0 worker ${worker}"
  vppctl set interface rx-placement VirtualEthernet0/0/${vEth} queue 1 worker $(($worker + 1))
  echo "vppctl set interface rx-placement VirtualEthernet0/0/${vEth} queue 1 worker $(($worker + 1))"
  worker=$(($worker + 2))
  if [[ "${worker}" == "8" ]]; then worker=0; fi
done

echo ""
echo "## vEdge Chain Started ##"
echo ""
