#! /bin/bash

idx=0
for id in $(virsh list | grep running | awk {'print $1}'); do
    intf[$idx]=$(virsh dumpxml $id | grep "/tmp/" | awk '{print $3}' | tr -d "'" | awk -F'/' '{print $3}' | tail -n 1)
    idx=$((idx + 1))
done

in_idx=0
not_in_idx=0

intfs=$(vppctl show hard | grep VirtualEth | wc -l)
for i in $(seq 0 $((intfs - 1))); do
    veth=$(vppctl show vhost VirtualEthernet0/0/${i} | grep "/tmp/" | awk '{print $3}' | awk -F '/' '{print $3}')
    match=0
    for ext in "${intf[@]}"; do
        if [ "$ext" == "$veth" ]; then
            in_use[${in_idx}]=$i
            ((++in_idx))
            match=1
            break
        fi
    done
    if [ "${match}" == "0" ]; then
      not_in_use[${not_in_idx}]=$i
      ((++not_in_idx))
    fi
done

echo "in_use:  ${in_use[@]}"
echo "not_in_use: ${not_in_use[@]}"

threads=$(vppctl show threads | grep "vpp_wk" | wc -l)

worker=0
for i in ${in_use[@]}; do
  vppctl set interface rx-placement VirtualEthernet0/0/${i} queue 0 worker ${worker}
  worker=$((($worker + 1) % $threads))
done

worker=0
for i in ${not_in_use[@]}; do
  vppctl set interface rx-placement VirtualEthernet0/0/${i} queue 0 worker ${worker}
  worker=$((($worker + 1) % $threads))
done
