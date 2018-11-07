#! /bin/bash

chains="$1"
cleanup="$2"

## Input validation ##
if [[ -n ${chains//[0-9]/} ]] || [[ "$chains" -le "1" ]] ; then
  echo "ERROR: Chains must be integer value higher than 1"
  echo "  Provided: $0 $1 $2 $3"
  echo "Usage: $0 <Chains> [clean|baseline]"
  exit 1
fi

if [[ "$chains" -gt "6" ]]; then
  if [ ! "${cleanup}" == "baseline" ] && [ ! "${cleanup}" == "clean" ]; then
    echo "ERROR - DEBUG: Only supports up to 6 chains"
    exit 1
  elif [ "${cleanup}" == "baseline" ] && [[ "$chains" -gt "8" ]]; then
    echo "ERROR - DEBUG: Baseline only supports up to 8 chains"
    exit 1
  fi
fi
######################

## Static parameters ##
if [ ! "${cleanup}" == "baseline" ]; then
  baseline=""
  main_cores=( 0 10 38 16 44 22 50 )
  worker_cores=( 0 12,40 14,42 18,46 20,48 24,52 26,54 )
else
  baseline="baseline"
  main_cores=( 0 4 32 10 38 16 44 22 50 )
  worker_cores=( 0 6,34 8,36 12,40 14,42 18,46 20,48 24,52 26,54 )
fi
######################

mydir=$(dirname $0)

cd $mydir

if [ "$cleanup" == "clean" ]; then
  # Only removes container, not image
  for chain in $(seq 1 $chains); do
    docker rm v${chain}Edge -f
  done
  exit 0
fi

./build_container.sh

for chain in $(seq 1 $chains); do
  if [ -z "$(docker ps | grep v${chain}Edge)" ]; then
    docker run --privileged --cpus 3 --cpuset-cpus ${main_cores[${chain}]},${worker_cores[${chain}]} --device=/dev/hugepages/:/dev/hugepages/ -v "/etc/vpp/sockets/:/root/sockets/" -t -d --name v${chain}Edge vedge_chain /vEdge/configure.sh ${chain} ${chains} ${baseline}
  fi
  echo "v${chain}Edge container started"
  sleep 10
done

# Restart VPP to get correct queue pinning of Memifs
service vpp restart
