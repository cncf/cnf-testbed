#! /bin/bash

cid=$1
total=$2

## Input validation ##
if [ ! -e "/vEdge/in_container" ]; then
  echo "ERROR - Looks like script is being run outside of container!"
  exit 1
fi

if [[ "$#" -ne "2" ]]; then
  echo "ERROR - Two input arguments required"
  echo "  Usage: $0 <Chain ID> <Total Chains>"
  exit 1
fi

if [[ -n ${cid//[0-9]/} ]] || [[ -n ${total//[0-9]/} ]]; then
  echo "ERROR: Inputs must be an integer values"
  echo "  Provided: $0 $1 $2"
  echo "  Usage: $0 <Chain ID> <Total Chains>"
  exit 1
fi

if [[ "$cid" -gt "8" ]] || [[ "$total" -gt "8" ]]; then
  echo "ERROR - DEBUG: Only supports up to 6 chains"
  exit 1
fi

if [[ "${total}" == "1" ]]; then
  echo "ERROR - DEBUG: Script currently doesn't support single chain"
  exit 1
fi
######################

## Static parameters ##
queues=1 # This could be moved out of this script as it also impacts host VPP
trex_mac1=3c:fd:fe:bd:f8:60
trex_mac2=3c:fd:fe:bd:f8:61
main_cores=( 0 5 61 8 64 11 67 14 70 ) # The same list is required in the 'run_container.sh' script
worker_cores=( 0 6,62 7,63 9,65 10,66 12,68 13,69 15,71 16,72 ) # The same list is required in the 'run_container.sh' script
######################

## Functions ##
set_startup_vals() {
  cnfid=${cid}
  main_core=${main_cores[${cid}]}
  workers=${worker_cores[${cid}]}
}

set_socket_names() {
  if [[ "${cid}" == "1" ]]; then
    sock1=memif1
    sock2=int1
  elif [[ "${cid}" == "${total}" ]]; then
    sock1=int$(($cid - 1))
    sock2=memif2
  else
    sock1=int$(($cid - 1))
    sock2=int${cid}
  fi  
}

set_memif_ids() {
  if [[ "${cid}" == "1" ]]; then
    memid1=1
    memid2=10
  elif [[ "${cid}" == "${total}" ]]; then
    memid1=$(($cid + 8))
    memid2=2
  else
    memid1=$(($cid + 8))
    memid2=$(($cid + 9))
  fi
}

set_macs() {
  if [[ "${cid}" == "1" ]]; then
    mac1=52:54:00:00:00:aa
    mac2=52:54:00:00:01:bb
  elif [[ "${cid}" == "${total}" ]]; then
    mac1=52:54:00:00:0${cid}:aa
    mac2=52:54:00:00:00:bb
  else
    mac1=52:54:00:00:0${cid}:aa
    mac2=52:54:00:00:0${cid}:bb
  fi
}

set_owners() {
  if [[ "${cid}" == "${total}" ]]; then
    owner1=slave
    owner2=slave
  else
    owner1=slave
    owner2=master
  fi
}

set_subnets() {
  if [[ "${cid}" == "1" ]]; then
    subnet1=172.16.10.10/24
    subnet2=172.16.31.10/24
  elif [[ "${cid}" == "${total}" ]]; then
    subnet1=172.16.$(($cid + 29)).11/24
    subnet2=172.16.20.10/24
  else    
    subnet1=172.16.$(($cid + 29)).11/24
    subnet2=172.16.$(($cid + 30)).10/24
  fi
}

set_remote_ips() {
  if [[ "${cid}" == "1" ]]; then
    remip1=172.16.10.100
    remip2=172.16.31.11
  elif [[ "${cid}" == "${total}" ]]; then
    remip1=172.16.$(($cid + 29)).10
    remip2=172.16.20.100
  else    
    remip1=172.16.$(($cid + 29)).10
    remip2=172.16.$(($cid + 30)).11
  fi
}

set_remote_macs() {
  if [[ "${cid}" == "1" ]]; then
    remmac1=${trex_mac1}
    remmac2=52:54:00:00:02:aa
  elif [[ "${cid}" == "${total}" ]]; then
    remmac1=52:54:00:00:0$(($cid - 1)):bb
    remmac2=${trex_mac2}
  else    
    remmac1=52:54:00:00:0$(($cid - 1)):bb
    remmac2=52:54:00:00:0$(($cid + 1)):aa
  fi
}

###############

set_startup_vals
set_socket_names
set_memif_ids
set_macs
set_owners
set_subnets
set_remote_ips
set_remote_macs

bash -c "cat > /etc/vpp/startup.conf" <<EOF
unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
  gid vpp
  startup-config /etc/vpp/setup.gate
  cli-prompt CNF#${cnfid}:
}

api-trace {
  on
}

api-segment {
  gid vpp
}

cpu {
  main-core ${main_core}
  corelist-workers ${workers}
}

dpdk {
  no-pci
  # dev default {
    # num-rx-queues 2
    # num-rx-desc 1024
    # num-tx-desc 1024
  # }
  # dev 0000:18:00.2
  # uio-driver igb_uio
  no-multi-seg
  no-tx-checksum-offload
}

plugins {
  plugin default { disable }
  plugin dpdk_plugin.so { enable }
  plugin memif_plugin.so { enable }
}
EOF

bash -c "cat > /etc/vpp/setup.gate" <<EOF
bin memif_socket_filename_add_del add id 1 filename /root/sockets/${sock1}.sock
bin memif_socket_filename_add_del add id 2 filename /root/sockets/${sock2}.sock
create interface memif id ${memid1} socket-id 1 hw-addr ${mac1} ${owner1} rx-queues ${queues} tx-queues ${queues}
create interface memif id ${memid2} socket-id 2 hw-addr ${mac2} ${owner2} rx-queues ${queues} tx-queues ${queues}
set int ip addr memif1/${memid1} ${subnet1}
set int ip addr memif2/${memid2} ${subnet2}
set int state memif1/${memid1} up
set int state memif2/${memid2} up

set ip arp static memif1/${memid1} ${remip1} ${remmac1}
set ip arp static memif2/${memid2} ${remip2} ${remmac2}

ip route add 172.16.64.0/18 via ${remip1}
ip route add 172.16.192.0/18 via ${remip2}
EOF

cat /etc/vpp/startup.conf
cat /etc/vpp/setup.gate

/usr/bin/vpp -c /etc/vpp/startup.conf
