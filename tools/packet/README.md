# Useful tools for working with Equinix Metal

capacity.sh {quantity}


Reads environment variables:
  NODE_COUNT=${1:-$NODE_COUNT}
  QUANTITY=${NODE_COUNT:-2}
  FACILITY=${PACKET_FACILITY:-ewr1}
  PLAN=${PLAN:-m2.xlarge.x86}

Returns availability of nodes in the defined facility and plan.


