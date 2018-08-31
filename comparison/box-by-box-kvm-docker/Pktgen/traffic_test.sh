#! /bin/bash

iterations=1
nfvbench="sudo docker exec -it nfvbench nfvbench -c /tmp/nfvbench/nfvbench_config.cfg"
prefix="aug_21_test" # Change to something identifiable

for iter in $(seq 1 $iterations); do
  $nfvbench --rate pdr_ndr | sudo tee -a results/${prefix}_iter_${iter}.log
done
