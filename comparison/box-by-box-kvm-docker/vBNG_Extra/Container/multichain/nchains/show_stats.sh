#! /bin/bash

chains="$1"

for i in $(seq 1 $chains); do
  echo "## v${i}Edge:"
  docker exec -it v${i}Edge vppctl show int
  echo ""
done
