#! /bin/bash

numvfs=8
logfile=/var/log/port_setup.log

function logtime() {
  date +"%Y-%m-%d %T"
}

logfile=/var/log/port_setup.log

if [ ! -e "/usr/bin/lspci" ]; then
  apt-get --no-install-recommends install -y pciutils
fi

pf_ids=($(lspci | grep Eth | grep -v Virtual | awk '{print $1}' | head -n 3 | tail -n 2))

if [ ! "${#pf_ids[@]}" == "0" ]; then
  if [ ! -e "/sys/bus/pci/devices/0000:${pf_ids[0]}/sriov_numvfs" ]; then
    echo "[$(logtime)] Device virtualization (SRIOV) not enabled - Exiting" >> $logfile
    exit 0
  fi
else
  echo "[$(logtime)] NIC ports (PCI) not found - Exiting" >> $logfile
  exit 0
fi

for pf in ${pf_ids[@]}; do
  $(echo "${numvfs}" > /sys/bus/pci/devices/0000:$pf/sriov_numvfs)
done

vf_ids=($(lspci | grep Eth | grep Virtual | awk '{print $1}'))
vf_num=${#vf_ids[@]}

if [ "$vf_num" == "0" ]; then
  echo "[$(logtime)] VFs not found - Exiting" >> $logfile
  exit 0
fi

if [ ! "$(($vf_num % 2))" == "0" ]; then
  echo "[$(logtime)] Odd number of VFs ($vf_num) - Exiting" >> $logfile
  exit 0
fi

vf_list=""
counter=0
for vf in ${vf_ids[@]}; do
  if [ "$((($counter) % 4))" -le "1" ]; then
    vf_list="$vf_list $vf"
  fi
  ((counter++))
done

if [ ! -z "$vf_list" ]; then
  echo "[$(logtime)] VF list:$vf_list" >> $logfile
else
  echo "[$(logtime)] VF list empty - Exiting" >> $logfile
  exit 0
fi

if [ ! -e "/opt/cnf_testbed/dpdk-devbind.py" ]; then
  echo "[$(logtime)] /opt/cnf_testbed/dpdk-devbind.py not found - Exiting" >> $logfile
  exit 0
else
  /usr/bin/python /opt/cnf_testbed/dpdk-devbind.py -b vfio-pci $vf_list
fi

echo "[$(logtime)] Configuration done" >> $logfile

exit 0
