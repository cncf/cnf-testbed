#!/bin/bash
docker run \
  --rm \
  --dns 147.75.69.23 --dns 8.8.8.8 \
  -v $(pwd)/data:/cncf/data \
  -v $(pwd)/override.tf:/cncf/packet/override.tf \
  -e NAME=packet \
  -e CLOUD=packet \
  -e COMMAND=deploy \
  -e BACKEND=file \
  -e TF_VAR_master_node_count=3 \
  -e TF_VAR_worker_node_count=1 \
  -e TF_VAR_packet_master_device_plan=t1.small \
  -e TF_VAR_packet_worker_device_plan=c1.xlarge \
  -e TF_VAR_packet_operating_system=ubuntu_18_04 \
  -e TF_VAR_packet_project_id=$PACKET_PROJECT_ID \
  -e PACKET_AUTH_TOKEN=$PACKET_AUTH_TOKEN \
  -ti registry.cidev.cncf.ci/cncf/cross-cloud/provisioning:master
