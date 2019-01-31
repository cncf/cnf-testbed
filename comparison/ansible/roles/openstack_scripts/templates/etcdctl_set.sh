#!/bin/bash

echo "export ETCDCTL_ENDPOINTS=http://$(hostname -I):2379"
echo "etcdctl cluster-health"
