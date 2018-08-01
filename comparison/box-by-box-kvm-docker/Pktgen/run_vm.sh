#! /bin/bash

run_nfvbench() {
  cmd="sudo docker exec -it nfvbench nfvbench -c /tmp/nfvbench/nfvbench_config.cfg"
  if [ ! -z "$1" ]; then
    vagrant ssh -c "$cmd --rate ${1}"
  else
    vagrant ssh -c "$cmd"
  fi
}

# Only run configuration is sockets are available
# Consider moving variables to top-level script (vBNG_vm_test.sh)
SOCKET_DIR="/var/run/vpp"
SOCKET_NAMES=( sock3.sock sock4.sock )
for sock in "${SOCKET_NAMES[@]}"; do
  if [ ! -e "${SOCKET_DIR}/${sock}" ]; then
    echo "ERROR - Socket ${SOCKET_DIR}/${sock} not found"
    exit 1
  fi
done

cpus=( 4 5 6 )

input="$1"

mydir=$(dirname $0)

cd $mydir

if [ "$input" == "clean" ]; then
  vagrant destroy -f
  exit 0
elif [ ! -z "$input" ] && [[ ! "$input" == *"pps"* ]]; then
  echo "ERROR: Invalid input - Must be either 'clean' or number of pps"
  echo "       E.g. 2500pps, 3Kpps, 1Mpps (minimum 2002pps)"
  exit 1
fi

state=$(vagrant status | grep Pktgen | awk '{print $2}')
if [ "$state" == "running" ]; then
  run_nfvbench $input
  exit 0
fi 

vagrant up

id=$(virsh list | grep Pktgen_Pktgen | awk '{print $1}')
if [ -z "$id" ]; then
  echo "ERROR - Pktgen VM not running"
  exit 1
fi

virsh dumpxml --inactive --security-info $id > Pktgen.xml

line=$(grep -HrIin "<serial type='pty'>" Pktgen.xml | awk -F ':' '{print $2}')

sed -i "$((line-1))r Interfaces" Pktgen.xml

virsh define Pktgen.xml

vagrant reload

cmd="cp /vagrant/grub* . && chmod +x grub* && ./grub_config.sh"
vagrant ssh -c "$cmd"

sleep 15

cmd="cp /vagrant/boot* . && cp /vagrant/nfvb* . && chmod +x boot* && ./bootstrap.sh"
#cmd="cp /vagrant/boot* . && cp /vagrant/nfvb* . && chmod +x boot*"
vagrant ssh -c "$cmd"

count=0
new_id=$(virsh list | grep Pktgen_Pktgen | awk '{print $1}')
for cpu in "${cpus[@]}"; do
  virsh vcpupin ${new_id} ${count} ${cpu}
  (( count++ ))
done 

run_nfvbench $input
