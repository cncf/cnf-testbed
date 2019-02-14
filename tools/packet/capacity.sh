#!/bin/bash

NODE_COUNT=${1:-$NODE_COUNT}
QUANTITY=${NODE_COUNT:-2}
FACILITY=${PACKET_FACILITY:-ewr1}
PLAN=${PLAN:-m2.xlarge.x86}

curl -sX POST --header "Content-Type: application/json" \
             --header "Accept: application/json" \
             --header "X-Auth-Token: ${PACKET_API_TOKEN}" \
             --data "{\"servers\":[{\"facility\": \"${FACILITY}\",\"plan\": \"${PLAN}\",\"quantity\": \"${QUANTITY}\"}]}" https://api.packet.net/capacity | python -mjson.tool
