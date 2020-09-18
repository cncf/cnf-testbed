#! /bin/bash

chains="$1"

if [[ -n ${chains//[0-9]/} ]] || [ -z "$chains" ]; then
  echo "ERROR: Expecting number of chains (integer) as input"
  echo "Usage: $0 <chains>"
  exit 1
fi

total_rss=0
for i in $(seq 1 $chains); do
  CID=$(docker ps | grep v${i}Edge | awk '{print $1}')
  rss_val=$(cat /sys/fs/cgroup/memory/docker/${CID}*/memory.stat | \
	grep "total_rss" | grep -v "huge" | awk '{print $2}')
  if [[ ! -n ${rss_val//[0-9]/} ]]; then
    total_rss=$(($total_rss + $rss_val))
    rss_val=$(bc -l <<< "scale=2; ${rss_val}/1000000")
    echo "v${i}Edge RSS: ${rss_val} MB"
  fi
done
total_rss=$(bc -l <<< "scale=2; ${total_rss}/1000000")
echo ""
echo "Total RSS ($chains Chains): ${total_rss} MB"
