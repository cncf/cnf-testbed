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

if ${CREATE_PORTS}; then
for CHAIN in $(seq 1 ${CHAINS}); do
  for NODE in $(seq 1 ${NODES}); do
    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
      openstack port create ${CHAIN}_${NODE}_${NODES}_l --network ${left}
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --network ${right}
    elif [[ "${NODE}" == "1" ]]; then
      openstack port create ${CHAIN}_${NODE}_${NODES}_l --network ${left}
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --network ${middle1}
    elif [[ "${NODE}" == "${NODES}" ]]; then
      if [[ "${NODES}" == "2" ]]; then
        openstack port create ${CHAIN}_${NODE}_${NODES}_l --network ${middle1}
      else
        openstack port create ${CHAIN}_${NODE}_${NODES}_l --network ${middle2}
      fi
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --network ${right}
    else
      openstack port create ${CHAIN}_${NODE}_${NODES}_l --network ${middle1}
      openstack port create ${CHAIN}_${NODE}_${NODES}_r --network ${middle2}
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
cat > "$tmp_vnfconf" <<EOF
#!/bin/bash
passwd ubuntu <<EOL
ubuntu
ubuntu
EOL
cat >/etc/resolv.conf <<EOL
nameserver 8.8.8.8
nameserver 8.8.8.4
EOL

cat >/etc/rc.local <<EOL
#! /bin/bash

if [ ! -f /opt/beenthere ]; then

touch /opt/beenthere
# Download igb_uio.ko kernal module
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/base_image/shared/igb_uio.ko" -o /opt/igb_uio.ko

# Download and run vm build script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/base_image/vedge_vm_build.sh" -o /opt/vedge_vm_build.sh
cd /opt
chmod +x vedge_vm_build.sh
./vedge_vm_build.sh

# Download the dpdk-devbind script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/shared/dpdk-devbind.py" -o /opt/dpdk-devbind.py
cd /opt
chmod +x dpdk-devbind.py

# Download and run vm install script
curl -k -L "https://raw.githubusercontent.com/cncf/cnfs/$BRANCH/comparison/kubecon18-chained_nf_test/VNF_openstack/shared/vEdge_vm_install.sh" -o /opt/vEdge_vm_install.sh
cd /opt
chmod +x vEdge_vm_install.sh
./vEdge_vm_install.sh $CHAIN $NODE $NODES $REMMAC1 $REMMAC2

else
  echo "Skipping VPP install"
fi
EOL

chmod +x /etc/rc.local

sed -i -e '/auto ens3/,+6d' /etc/network/interfaces.d/50-cloud-init.cfg
sed -i -e '/auto ens4/,+6d' /etc/network/interfaces.d/50-cloud-init.cfg

reboot

EOF

        KEYPAIR=${KEYPAIR:-oskey}

        openstack server create ${CHAIN}_${NODE}_${NODES} --flavor vnf.3c --key-name ${KEYPAIR} --image xenial --nic port-id=${CHAIN}_${NODE}_${NODES}_l --nic port-id=${CHAIN}_${NODE}_${NODES}_r --nic port-id=${CHAIN}_${NODE}_${NODES}_e --config-drive True --user-data "$tmp_vnfconf"

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
