#!/bin/bash

echo "Starting vDNS container"
./vDNS/run_vm.sh

echo "Starting vDNSgen container and running tests"
./vDNSgen/run_vm_test.sh $1
