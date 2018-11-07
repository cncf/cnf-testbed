#! /bin/bash

chains="$1"

if [[ -n ${chains//[0-9]/} ]] || [ -z "$chains" ]; then
  echo "ERROR: Expecting number of chains (integer) as input"
  echo "Usage: $0 <chains>"
  exit 1
fi

for i in $(seq 1 $chains); do
  echo "###### v${i}Edge ######"
  docker exec -it v${i}Edge vppctl show int
  echo ""
done
