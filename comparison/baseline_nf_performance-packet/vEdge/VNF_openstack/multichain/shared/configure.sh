#! /bin/bash

cid=$1
total=$2

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

## Static parameters ##
trex_mac1=8a:fd:d5:d5:d6:b6
trex_mac2=06:9c:b3:cc:f0:62
#######################

set_subnets
set_remote_ips
set_remote_macs

## Pre-heating API (workaround)
sudo vppctl show int

intfs=($(sudo vppctl show int | grep Ethernet | awk '{print $1}'))
if [ ! "${#intfs[@]}" == "2" ]; then
  echo "ERROR: Number of interfaces should be 2 (is ${#intfs[@]})"
  exit 1
fi

# Create interface configuration for VPP
sudo bash -c "cat > /etc/vpp/setup.gate" <<EOF
set int state ${intfs[0]} up
set interface ip address ${intfs[0]} ${subnet1}

set int state ${intfs[1]} up
set interface ip address ${intfs[1]} ${subnet2}

set ip arp static ${intfs[0]} ${remip1} ${remmac1}
set ip arp static ${intfs[1]} ${remip2} ${remmac2}

ip route add 172.16.64.0/18 via ${remip1}
ip route add 172.16.192.0/18 via ${remip2}
EOF

sudo service vpp restart

