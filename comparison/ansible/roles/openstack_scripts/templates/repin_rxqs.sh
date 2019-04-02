#! /bin/bash

in_use=( 2 3 4 5 6 7 9 10 12 13 15 16 )
not_in_use=( 0 1 8 11 14 17 )
worker=0
for i in ${in_use[@]}; do
  vppctl set interface rx-placement VirtualEthernet0/0/${i} queue 0 worker ${worker}
  worker=$((($worker + 1) % 4))
done

worker=0
for i in ${not_in_use[@]}; do
  vppctl set interface rx-placement VirtualEthernet0/0/${i} queue 0 worker ${worker}
  worker=$((($worker + 1) % 4))
done
