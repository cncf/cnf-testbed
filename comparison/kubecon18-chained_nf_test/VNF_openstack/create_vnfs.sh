#!/bin/bash

# NOTE: Set the environment variables for VLANID_LEFT, VLANID_RIGHT, TREX_MAC1 and TREX_MAC2

# Network names
#left="vlan1076"
left="vlan${VLANID_LEFT}"
middle1="middle1"
middle2="middle2"
#right="vlan1078"
right="vlan${VLANID_RIGHT}"
external="netext"

[[ -n "$CREATE_PORTS" ]] || CREATE_PORTS=true
[[ -n "$CREATE_VMS" ]] || CREATE_VMS=true

#trex_macs=( e4:43:4b:2e:9f:e2 e4:43:4b:2e:9f:e3 )
trex_macs=( $TREX_MAC1 $TREX_MAC2 )

if [ $# -lt 2 ]; then
  echo "ERROR: this script requires 2 parameters"
  echo "USAGE: $0 <Chains> <Nodes>"
  exit 1
fi

CHAINS="${1}"
NODES="${2}"

function set_macs () {
    # Set interface MACs.
    #
    # Variable read:
    # - ${CHAIN} - Chain ID.
    # - ${NODE} - Node ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${MAC1} - East MAC.
    # - ${MAC2} - West MAC.

    CHAIN=$1
    NODE=$2
    NODES=$3

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        MAC1=52:53:0$(( ${CHAIN} - 1 )):00:00:aa
        MAC2=52:53:0$(( ${CHAIN} - 1 )):00:00:bb
    elif [[ "${NODE}" == "1" ]]; then
        MAC1=52:53:0$(( ${CHAIN} - 1 )):00:00:aa
        MAC2=52:53:0$(( ${CHAIN} - 1 )):00:01:bb
    elif [[ "${NODE}" == "${NODES}" ]]; then
        MAC1=52:53:0$(( ${CHAIN} - 1 )):00:0${NODE}:aa
        MAC2=52:53:0$(( ${CHAIN} - 1 )):00:00:bb
    else
        MAC1=52:53:0$(( ${CHAIN} - 1 )):00:0${NODE}:aa
        MAC2=52:53:0$(( ${CHAIN} - 1 )):00:0${NODE}:bb
    fi
}

if ${CREATE_PORTS}; then
for CHAIN in $(seq 1 ${CHAINS}); do
  for NODE in $(seq 1 ${NODES}); do
    set_macs $CHAIN $NODE $NODES
    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
      openstack port create ${CHAIN}_${NODE}_${NODES}_l --mac-address $MAC1 --network ${left}
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --mac-address $MAC2 --network ${right}
    elif [[ "${NODE}" == "1" ]]; then
      openstack port create ${CHAIN}_${NODE}_${NODES}_l --mac-address $MAC1 --network ${left}
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --mac-address $MAC2 --network ${middle1}
    elif [[ "${NODE}" == "${NODES}" ]]; then
      if [[ "${NODES}" == "2" ]]; then
        openstack port create ${CHAIN}_${NODE}_${NODES}_l --mac-address $MAC1 --network ${middle1}
      else
        openstack port create ${CHAIN}_${NODE}_${NODES}_l --mac-address $MAC1 --network ${middle2}
      fi
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --mac-address $MAC2 --network ${right}
    else
      openstack port create ${CHAIN}_${NODE}_${NODES}_l --mac-address $MAC1 --network ${middle1}
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --mac-address $MAC2 --network ${middle2}
    fi
    openstack port create ${CHAIN}_${NODE}_${NODES}_e --network ${left}
    float=$(openstack floating ip create ${external} | awk '/floating_ip_address/ {print $4}')
    port_id=$(openstack port list | grep ${CHAIN}_${NODE}_${NODES}_e | awk '{print $2}')
    openstack floating ip set --port=${port_id} ${float}
  done
done
fi

if ${CREATE_VMS}; then
for CHAIN in $(seq 1 ${CHAINS}); do
  for NODE in $(seq 1 ${NODES}); do
    if [[ -z "$(openstack server show ${CHAIN}_${NODE}_${NODES})" ]]; then  
      if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        REMMAC1="${trex_macs[0]}"
        REMMAC2="${trex_macs[1]}"
      elif [[ "${NODE}" == "1" ]]; then
        REMMAC1="${trex_macs[0]}"
        REMMAC2=$(openstack port show ${CHAIN}_$((NODE + 1))_${NODES}_l | awk '/ mac_address / {print $4}')
      elif [[ "${NODE}" == "${NODES}" ]]; then
        REMMAC1=$(openstack port show ${CHAIN}_$((NODE - 1))_${NODES}_r | awk '/ mac_address / {print $4}')
        REMMAC2="${trex_macs[1]}"
      else
        REMMAC1=$(openstack port show ${CHAIN}_$((NODE - 1))_${NODES}_r | awk '/ mac_address / {print $4}')
        REMMAC2=$(openstack port show ${CHAIN}_$((NODE + 1))_${NODES}_l | awk '/ mac_address / {print $4}')
      fi

      export BRANCH="master"
      tmp_vnfconf="$TEMPDIR/vnfconf-$RANDOM.cfg"

#cat > /tmp/vnfconf.cfg <<EOF
cat > $tmp_vnfconf <<EOF
#! /bin/bash
ifconfig ens3 down
ifconfig ens4 down

sed -i '/ens3:/,/set-name: ens4/d' /etc/netplan/50-cloud-init.yaml

/opt/vEdge_vm_install.sh $CHAIN $NODE $NODES $REMMAC1 $REMMAC2
EOF
        KEYPAIR=${KEYPAIR:-oskey}

        openstack server create ${CHAIN}_${NODE}_${NODES} --flavor vnf.3c --key-name ${KEYPAIR} --image vnf_base --nic port-id=${CHAIN}_${NODE}_${NODES}_l --nic port-id=${CHAIN}_${NODE}_${NODES}_r --nic port-id=${CHAIN}_${NODE}_${NODES}_e --config-drive True --user-data "$tmp_vnfconf"

        #rm /tmp/vnfconf.cfg
        rm "$tmp_vnfconf"
      else
        echo ""
        echo "Server ${CHAIN}_${NODE}_${NODES} already exists"
        echo ""
      fi
    done
  done
fi
