#! /bin/bash

CID=$(docker ps | grep vBNG | awk '{print $1}')
rss_val=$(cat /sys/fs/cgroup/memory/docker/${CID}*/memory.stat | \
	grep "total_rss" | grep -v "huge" | awk '{print $2}')
rss_val=$(bc -l <<< "scale=2; ${rss_val}/1000000")
echo "RSS: ${rss_val} MB"
