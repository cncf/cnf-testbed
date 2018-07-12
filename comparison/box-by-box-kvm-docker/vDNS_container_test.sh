#!/bin/bash

echo "Starting vDNS container"
./vDNS/run_container.sh


echo "Starting vDNSgen container and running tests"
./vDNSgen/run_container_test.sh $1
