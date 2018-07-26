#! /bin/bash

# Only run configuration is sockets are available
# Consider moving variables to top-level script (vBNG_vm_test.sh)
SOCKET_DIR="/var/run/vpp"
SOCKET_NAMES=( sock1.sock sock2.sock )
for sock in "${SOCKET_NAMES[@]}"; do
  if [ ! -e "${SOCKET_DIR}/${sock}" ]; then
    echo "ERROR - Socket ${SOCKET_DIR}/${sock} not found"
    exit 1
  fi
done

mydir=$(dirname $0)

cd $mydir

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

cmd="cp /vagrant/v_bng_* . && chmod +x v_bng_* && ./v_bng_install.sh"
vagrant ssh -c "$cmd"

echo ""
echo "## vBNG Started ##"
echo ""
