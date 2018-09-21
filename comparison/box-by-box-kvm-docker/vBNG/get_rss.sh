#! /bin/bash

VID=$(virsh list | grep vBNG_vBNG | awk '{print $1}')
rss_val=$(virsh dommemstat ${VID} | \
	        grep "rss" | awk '{print $2}')
rss_val=$(bc -l <<< "scale=2; ${rss_val}/976.5625")
echo "RSS: ${rss_val} MB"
