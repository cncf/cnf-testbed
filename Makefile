#Global Vars
DEPLOY_NAME := cnftestbed
PROJECT_ROOT := ${CURDIR}
FACILITY := ewr1
VLAN_SEGMENT := $(DEPLOY_NAME)
NIC_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/packet_gen_nics.env

# Default vars
#HW
USE_RESERVED := false
OPERATING_SYSTEM := ubuntu_18_04
#HW-K8s
ifeq (hw_k8s,$(firstword $(MAKECMDGOALS)))
	include Makefile.hw_k8s
endif
#HW-Pktgen
ifeq (hw_pktgen,$(firstword $(MAKECMDGOALS)))
	include Makefile.hw_pktgen
endif
# GoGTP multi-node
ifeq (gogtp_multi,$(firstword $(MAKECMDGOALS)))
	include Makefile.gogtp_multi
endif
# CPU Isolation
ifeq (isolcpus,$(firstword $(MAKECMDGOALS)))
        include Makefile.isolcpus
endif
# PktGen
NIC_TYPE := "-e quad_intel=true"
ifeq (pktgen,$(firstword $(MAKECMDGOALS)))
	include Makefile.pktgen
endif
#K8s
RELEASE_TYPE := stable
#vSwitch
ifeq (vswitch,$(firstword $(MAKECMDGOALS)))
	include Makefile.vswitch
endif


# If load_envs is passed as the second argument, store all following arguments.
ifeq (load_envs,$(word 2, $(MAKECMDGOALS)))
  LOAD_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(LOAD_ARGS):;@:)
endif

# Use the 3rd passed argument as a file path and include all vars in that file.
ifeq (load_envs,$(firstword $(LOAD_ARGS)))
	include $(word 2, $(LOAD_ARGS))
endif

# Update vars after loading env file
HOSTS_FILE := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/kubernetes.env
KUBECONFIG := $(PROJECT_ROOT)/data/$(DEPLOY_NAME)/mycluster/artifacts/admin.conf

deps : SHELL := /bin/bash
deps:
	mkdir -p data/bin
	wget https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 -O data/bin/yq
	chmod +x data/bin/yq
	pushd $(PROJECT_ROOT)/tools/packet_api && docker build -t ubuntu:packet_api . && popd
	pushd $(PROJECT_ROOT)/tools/deploy && docker build -t cnfdeploytools:latest . && popd

.PHONY: hw_k8s
hw_k8s: hw_tools

.PHONY: hw_pktgen
hw_pktgen: hw_tools

hw_tools:
	DEPLOY_NAME=$(DEPLOY_NAME) USE_RESERVED=$(USE_RESERVED) FACILITY=$(FACILITY) OPERATING_SYSTEM=$(OPERATING_SYSTEM) NODE_GROUP_ONE_NAME=$(NODE_GROUP_ONE_NAME) NODE_GROUP_TWO_NAME=$(NODE_GROUP_TWO_NAME) NODE_GROUP_THREE_NAME=$(NODE_GROUP_THREE_NAME) NODE_GROUP_ONE_COUNT=$(NODE_GROUP_ONE_COUNT) NODE_GROUP_TWO_COUNT=$(NODE_GROUP_TWO_COUNT) NODE_GROUP_THREE_COUNT=$(NODE_GROUP_THREE_COUNT) NODE_GROUP_ONE_DEVICE_PLAN=$(NODE_GROUP_ONE_DEVICE_PLAN) NODE_GROUP_TWO_DEVICE_PLAN=$(NODE_GROUP_TWO_DEVICE_PLAN) NODE_GROUP_THREE_DEVICE_PLAN=$(NODE_GROUP_THREE_DEVICE_PLAN) STATE_FILE=$(STATE_FILE) NODE_FILE=$(NODE_FILE) tools/hardware_provisioning.sh

.PHONY: k8s
k8s: config provision

config:
	HOSTS_FILE=$(HOSTS_FILE) DEPLOY_NAME=$(DEPLOY_NAME) RELEASE_TYPE=$(RELEASE_TYPE)  tools/kubernetes_provisioning.sh generate_config

provision:
	tools/kubernetes_provisioning.sh provision

.PHONY: gogtp_multi
gogtp_multi: gogtp_multi_tools

gogtp_multi_tools:
	DEPLOY_NAME=$(DEPLOY_NAME) PROJECT_ROOT=$(PROJECT_ROOT) FACILITY=$(FACILITY) VLAN_SEGMENT=$(VLAN_SEGMENT) PLAYBOOK=$(PLAYBOOK) KUBECONFIG=$(KUBECONFIG) tools/kubernetes_provisioning.sh gogtp_multi

.PHONY: isolcpus
isolcpus: isolcpus_playbook

isolcpus_playbook:
	DEPLOY_NAME=$(DEPLOY_NAME) PROJECT_ROOT=$(PROJECT_ROOT) FACILITY=$(FACILITY) VLAN_SEGMENT=$(VLAN_SEGMENT) PLAYBOOK=$(PLAYBOOK) KUBECONFIG=$(KUBECONFIG) tools/kubernetes_provisioning.sh isolcpus

.PHONY: vswitch
vswitch: vswitch_tools

vswitch_tools:
	DEPLOY_NAME=$(DEPLOY_NAME) PROJECT_ROOT=$(PROJECT_ROOT) FACILITY=$(FACILITY) VLAN_SEGMENT=$(VLAN_SEGMENT) PLAYBOOK=$(PLAYBOOK) KUBECONFIG=$(KUBECONFIG) tools/kubernetes_provisioning.sh vswitch

.PHONY: pktgen
pktgen: pktgen_tools
pktgen_tools:
	DEPLOY_NAME=$(DEPLOY_NAME) PROJECT_ROOT=$(PROJECT_ROOT) NODE_FILE=$(NODE_FILE) NIC_FILE=$(NIC_FILE) NIC_TYPE=$(NIC_TYPE) FACILITY=$(FACILITY) VLAN_SEGMENT=$(VLAN_SEGMENT) PLAYBOOK=$(PLAYBOOK) tools/packet_generator_provisioning.sh


snake : PKTGEN_ETH2 := $$(cat $(NIC_FILE) | awk 'NR==1{print $1}')
snake : PKTGEN_ETH3 := $$(cat $(NIC_FILE) | awk 'NR==2{print $1}')
snake:
	docker run -v $(KUBECONFIG):/tmp/admin.conf -v $(PROJECT_ROOT)/examples/use_case/3c2n-csc/:/tmp/3c2n-csc -e KUBECONFIG=/tmp/admin.conf -ti alpine/helm install csc --set nfvbench_macs={$(PKTGEN_ETH2),$(PKTGEN_ETH3)} /tmp/3c2n-csc/csc/
