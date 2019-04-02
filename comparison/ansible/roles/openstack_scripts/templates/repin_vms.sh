#! /bin/bash

main=( 6 34 12 40 18 46 )
worker1=( 8 10 14 16 20 22 )
worker2=( 36 38 42 44 48 50 )
idx=0
for id in $(virsh list | grep running | awk {'print $1}'); do
  echo "ID: $id"
  virsh vcpupin ${id} 0 ${main[$idx]}
  virsh vcpupin ${id} 1 ${worker1[$idx]}
  virsh vcpupin ${id} 2 ${worker2[$idx]}
  virsh emulatorpin ${id} ${main[$idx]},${worker1[$idx]},${worker2[$idx]}
  idx=$((idx + 1))
done
