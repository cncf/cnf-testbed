#! /bin/bash

#parse_string() {
#  # Stores array output in "out_arr"
#  cleaned=$(echo $1 | sed 's/^|//; s/|$//; s/[ ]*|[ ]*/|/g;')
#  out_arr=$(awk '{split($0,arr,"|")} END {for(n in arr){ print arr[n] }}' <<< $cleaned)
#}

#config_file="vBNG_vm.conf"

# Update VPP configuration to match vBNG test case
#if ! cmp -s "/etc/vpp/setup.gate" "VPP_Configs/${config_file}" ; then
#  echo "Updating VPP configuration"
#  cp VPP_Configs/${config_file} /etc/vpp/setup.gate
#  service vpp restart
#  sleep 5
#fi

if [ -f "/tmp/nfvbench.output" ]; then
  rm /tmp/nfvbench.output
fi

input="$1"

./vBNG/run_vm.sh "$input"

#./Pktgen/run_vm.sh "$input" 2>&1 | tee /tmp/nfvbench.output

#if [[ "$input" == *"pps"* ]]; then
#  # Collect throughput stats
#  ## 1-2:Req_TX_bps  3-4:Act_TX_bps
#  ## 5-6:RX_bps      7-8:Req_TX_pps
#  ## 9-10:Act_TX_pps 11-12:RX_pps
#  parse_string "$(cat /tmp/nfvbench.output | grep Total)"
#  pkt_stats=(${out_arr[@]})
#  parse_string "$(cat /tmp/nfvbench.output | grep '68 |')"
#  pkt_loss=(${out_arr[@]})
#  # Collect memory (RSS) stats
#  VID=$(virsh list | grep vBNG_vBNG | awk '{print $1}')
#  rss_val=$(virsh dommemstat ${VID} | \
#            grep "rss" | awk '{print $2}')
#  rss_val=$(bc -l <<< "scale=2; ${rss_val}/976.5625")
#  # Print output
#  echo ""
#  echo "##### Stat Summary #####"
#  echo ""
#  echo "Throughput:"
#  echo "  Requested TX: ${pkt_stats[7]} ${pkt_stats[8]}"\
#       "(${pkt_stats[1]} ${pkt_stats[2]})"
#  echo "  Actual TX:    ${pkt_stats[9]} ${pkt_stats[10]}"\
#       "(${pkt_stats[3]} ${pkt_stats[4]})"
#  echo "  Throughput:   ${pkt_stats[11]} ${pkt_stats[12]}"\
#       "(${pkt_stats[5]} ${pkt_stats[6]})" 
#  echo "  Packet loss:  ${pkt_loss[1]}"
#  echo ""
#  echo "Memory:"
#  echo "  RSS: ${rss_val} MB"
#  echo ""
#fi
