#Global Vars
DEPLOY_NAME := cnftestbed
PROJECT_ROOT := $$(pwd -P)
FACILITY := ewr1
VLAN_SEGMENT := $(DEPLOY_NAME)
NIC_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/packet_gen_nics.env

#HW
USE_RESERVED := false
OPERATING_SYSTEM := ubuntu_18_04

# PktGen
NIC_TYPE := "-e quad_intel=true"

#K8s
RELEASE_TYPE := stable
HOSTS_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/kubernetes.env

#vSwitch
KUBECONFIG := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/mycluster/artifacts/admin.conf

deps:
	mkdir -p data/bin
	wget https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 -O data/bin/yq
	chmod +x data/bin/yq

.PHONY: hw_k8s
hw_k8s : STATE_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/kubernetes.tfstate
hw_k8s : NODE_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/kubernetes.env
hw_k8s : NODE_GROUP_ONE_NAME := $(DEPLOY_NAME)-master
hw_k8s : NODE_GROUP_TWO_NAME := $(DEPLOY_NAME)-worker
hw_k8s : NODE_GROUP_ONE_COUNT := 3
hw_k8s : NODE_GROUP_TWO_COUNT := 1
hw_k8s : NODE_GROUP_ONE_DEVICE_PLAN := c1.small.x86
hw_k8s : NODE_GROUP_TWO_DEVICE_PLAN := n2.xlarge.x86
hw_k8s: hw

.PHONY: hw_pktgen
hw_pktgen : STATE_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/packet_gen.tfstate
hw_pktgen : NODE_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/packet_gen.env
hw_pktgen : NODE_GROUP_ONE_NAME := $(DEPLOY_NAME)-pktgen
hw_pktgen : NODE_GROUP_ONE_COUNT := 1
hw_pktgen : NODE_GROUP_TWO_COUNT := 0
hw_pktgen : NODE_GROUP_ONE_DEVICE_PLAN := n2.xlarge.x86
hw_pktgen: hw

hw:
	DEPLOY_NAME=$(DEPLOY_NAME) USE_RESERVED=$(USE_RESERVED) FACILITY=$(FACILITY) OPERATING_SYSTEM=$(OPERATING_SYSTEM) NODE_GROUP_ONE_NAME=$(NODE_GROUP_ONE_NAME) NODE_GROUP_TWO_NAME=$(NODE_GROUP_TWO_NAME) NODE_GROUP_ONE_COUNT=$(NODE_GROUP_ONE_COUNT) NODE_GROUP_TWO_COUNT=$(NODE_GROUP_TWO_COUNT) NODE_GROUP_ONE_DEVICE_PLAN=$(NODE_GROUP_ONE_DEVICE_PLAN) NODE_GROUP_TWO_DEVICE_PLAN=$(NODE_GROUP_TWO_DEVICE_PLAN) STATE_FILE=$(STATE_FILE) NODE_FILE=$(NODE_FILE) tools/hardware_provisioning.sh

.PHONY: k8s
k8s: config provision

config:
	HOSTS_FILE=$(HOSTS_FILE) DEPLOY_NAME=$(DEPLOY_NAME) RELEASE_TYPE=$(RELEASE_TYPE)  tools/kubernetes_provisioning.sh generate_config

provision:
	tools/kubernetes_provisioning.sh provision

vswitch : PLAYBOOK := k8s_worker_vswitch_quad_intel.yml
vswitch:
	DEPLOY_NAME=$(DEPLOY_NAME) PROJECT_ROOT=$(PROJECT_ROOT) FACILITY=$(FACILITY) VLAN_SEGMENT=$(VLAN_SEGMENT) PLAYBOOK=$(PLAYBOOK) KUBECONFIG=$(KUBECONFIG) tools/kubernetes_provisioning.sh vswitch

pktgen : NODE_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/packet_gen.env
pktgen : PLAYBOOK := packet_generator.yml
pktgen:
	DEPLOY_NAME=$(DEPLOY_NAME) PROJECT_ROOT=$(PROJECT_ROOT) NODE_FILE=$(NODE_FILE) NIC_FILE=$(NIC_FILE) NIC_TYPE=$(NIC_TYPE) FACILITY=$(FACILITY) VLAN_SEGMENT=$(VLAN_SEGMENT) PLAYBOOK=$(PLAYBOOK) tools/packet_generator_provisioning.sh


snake : PKTGEN_ETH2 := $$(cat $(NIC_FILE) | awk 'NR==1{print $1}')
snake : PKTGEN_ETH3 := $$(cat $(NIC_FILE) | awk 'NR==2{print $1}')
snake:
	docker run -v $(KUBECONFIG):/tmp/admin.conf -v $(PROJECT_ROOT)/examples/use_case/3c2n-csc/:/tmp/3c2n-csc -e KUBECONFIG=/tmp/admin.conf -ti alpine/helm install csc --set nfvbench_macs={$(PKTGEN_ETH2),$(PKTGEN_ETH3)} /tmp/3c2n-csc/csc/
