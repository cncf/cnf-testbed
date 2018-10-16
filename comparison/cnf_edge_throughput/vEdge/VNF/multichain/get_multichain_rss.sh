#! /bin/bash

chains="$1"

if [[ -n ${chains//[0-9]/} ]] || [ -z "$chains" ]; then
  echo "ERROR: Expecting number of chains (integer) as input"
  echo "Usage: $0 <chains>"
  exit 1
fi

total_rss=0
for i in $(seq 1 $chains); do
  VID=$(virsh list | grep multichain_v${i}Edge | awk '{print $1}')
  rss_val=$(virsh dommemstat ${VID} | \
          grep "rss" | awk '{print $2}')
  total_rss=$(($total_rss + $rss_val))
  rss_val=$(bc -l <<< "scale=2; ${rss_val}/976.5625")
  echo "v${i}Edge RSS: ${rss_val} MB"
done
total_rss=$(bc -l <<< "scale=2; ${total_rss}/976.5625")
echo ""
echo "Total RSS ($chains Chains): ${total_rss} MB"

