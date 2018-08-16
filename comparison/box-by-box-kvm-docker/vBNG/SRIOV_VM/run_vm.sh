#! /bin/bash

# Only run configuration is sockets are available
# Consider moving variables to top-level script (vBNG_vm_test.sh)
#SOCKET_DIR="/var/run/vpp"
#SOCKET_NAMES=( sock1.sock sock2.sock )
#for sock in "${SOCKET_NAMES[@]}"; do
#  if [ ! -e "${SOCKET_DIR}/${sock}" ]; then
#    echo "ERROR - Socket ${SOCKET_DIR}/${sock} not found"
#    exit 1
#  fi
#done

cpus=( 7 8 9 )

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

vagrant up

id=$(virsh list | grep vBNG_vBNG | awk '{print $1}')
if [ -z "$id" ]; then
  echo "ERROR - vBNG VM not running"
  exit 1
fi

count=0
new_id=$(virsh list | grep vBNG_vBNG | awk '{print $1}')
for cpu in "${cpus[@]}"; do
  virsh vcpupin ${new_id} ${count} ${cpu}
  (( count++ ))
done

#vagrant reload

#virsh dumpxml --inactive --security-info $id > vBNG.xml

#line=$(grep -HrIin "<serial type='pty'>" vBNG.xml | awk -F ':' '{print $2}')

#sed -i "$((line-1))r Interfaces" vBNG.xml

#virsh define vBNG.xml

#vagrant reload

#cmd="cp /vagrant/v_bng_* . && chmod +x v_bng_* && ./v_bng_install.sh"
#cmd="/vagrant/vnf_vbng_install.sh"
#vagrant ssh -c "$cmd"

echo ""
echo "## vBNG Started ##"
echo ""
