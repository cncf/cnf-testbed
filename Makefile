# USE_RESERVED=${USE_RESERVED:-false}
# DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
# PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
# PACKET_OS=${PACKET_OS:-ubuntu_16_04}
# MASTER_COUNT=${MASTER_COUNT:-1}
# WORKER_COUNT=${WORKER_COUNT:-1}
# PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
# VLAN_SEGMENT=${VLAN_SEGMENT:-$DEPLOY_NAME}
# PLAYBOOK=${PLAYBOOK:-k8s_worker_vswitch_quad_intel.yml}
# RELEASE_TYPE=${RELEASE_TYPE:-stable}
# HOSTS_FILE=${HOSTS_FILE:-$(pwd)/data/$DEPLOY_NAME/nodes.env}

PROJECT_ROOT := $$(pwd -P)
DEPLOY_NAME := cnftestbed
KUBECONFIG := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/mycluster/artifacts/admin.conf
MASTER_PLAN = m2.xlarge.x86
WORKER_PLAN = n2.xlarge.x86
PACKET_PROJECT_NAME = 'Cross-Cloud CI'
PLAYBOOK := k8s_worker_vswitch_quad_intel.yml
hw:
	MASTER_PLAN=$(MASTER_PLAN) WORKER_PLAN=$(WORKER_PLAN) tools/hardware_provisioning.sh

.PHONY: k8s
k8s: config provision

config:
	tools/kubernetes_provisioning.sh generate_config

provision:
	tools/kubernetes_provisioning.sh provision

vswitch:
	PACKET_PROJECT_NAME=$(PACKET_PROJECT_NAME) PROJECT_ROOT=$(PROJECT_ROOT) PLAYBOOK=$(PLAYBOOK) tools/kubernetes_provisioning.sh vswitch

pktgen:

snake:
	docker run -v $(KUBECONFIG):/tmp/admin.conf -v $(PROJECT_ROOT)/examples/use_case/3c2n-csc/:/tmp/3c2n-csc -e KUBECONFIG=/tmp/admin.conf -ti alpine/helm install csc /tmp/3c2n-csc/csc/
