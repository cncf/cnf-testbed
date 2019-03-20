#!/bin/bash
myname=$(basename $0)
myfullpath=$(readlink -f $0)
mypath=$(dirname $myfullpath)
project_root=$(cd ../ ; pwd -P)
tool_path="${project_root}/tools"
deploy_tools_path="${tool_path}/deploy"


VPP_VSWITCH=true

######  

## Deploy k8s
SECONDS=0

docker run \
  --rm \
  --dns 147.75.69.23 --dns 8.8.8.8 \
  -v $(pwd)/data:/cncf/data \
  -v $(pwd)/k8s_cluster_override.tf:/cncf/packet/override.tf \
  -v $(pwd)/k8s_worker_override.tf:/cncf/packet/modules/worker/override.tf \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v "${project_root}/comparison/ansible:/ansible" \
  -e NAME=$NAME \
  -e CLOUD=packet \
  -e COMMAND=deploy \
  -e BACKEND=file \
  -e TF_VAR_playbook=$PLAYBOOK \
  -e TF_VAR_master_node_count=$MASTER_NODE_COUNT \
  -e TF_VAR_worker_node_count=$WORKER_NODE_COUNT \
  -e TF_VAR_packet_master_device_plan=$MASTER_NODE_TYPE \
  -e TF_VAR_packet_worker_device_plan=$WORKER_NODE_TYPE \
  -e TF_VAR_packet_operating_system=$NODE_OS \
  -e TF_VAR_packet_facility=$FACILITY \
  -e TF_VAR_etcd_artifact=https://storage.googleapis.com/etcd/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz \
  -e TF_VAR_cni_artifact=https://github.com/containernetworking/cni/releases/download/${CNI_VERSION}/cni-amd64-${CNI_VERSION}.tgz \
  -e TF_VAR_cni_plugins_artifact=https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz \
  -e TF_VAR_kubelet_artifact=https://storage.googleapis.com/kubernetes-release/release/${K8S_RELEASE}/bin/linux/amd64/kubelet \
  -e TF_VAR_kube_apiserver_artifact=https://storage.googleapis.com/kubernetes-release/release/${K8S_RELEASE}/bin/linux/amd64/kube-apiserver \
  -e TF_VAR_kube_controller_manager_artifact=https://storage.googleapis.com/kubernetes-release/release/${K8S_RELEASE}/bin/linux/amd64/kube-controller-manager \
  -e TF_VAR_kube_scheduler_artifact=https://storage.googleapis.com/kubernetes-release/release/${K8S_RELEASE}/bin/linux/amd64/kube-scheduler \
  -e TF_VAR_kube_proxy_image=gcr.io/google_containers/kube-proxy \
  -e TF_VAR_kube_proxy_tag=${K8S_RELEASE} \
  -e TF_VAR_packet_project_id=$PACKET_PROJECT_ID \
  -e PACKET_AUTH_TOKEN=$PACKET_AUTH_TOKEN \
  -ti registry.cidev.cncf.ci/cncf/cross-cloud/provisioning:master
  
K8S_ELAPSED_TIME=$SECONDS
echo "$(($K8S_ELAPSED_TIME / 60)) minutes and $(($K8S_ELAPSED_TIME % 60)) seconds elapsed - K8s Deploy."

if [ "$VPP_VSWITCH" = "true" ] ; then
   SECONDS=0
   $(project_root)/tools/deploy_k8s_vppvswitch.sh $(pwd)/data/kubeconfig
   VSWITCH_ELAPSED_TIME=$SECONDS
   echo "$(($VSWITCH_ELAPSED_TIME / 60)) minutes and $(($VSWITCH_ELAPSED_TIME % 60)) seconds elapsed - VPP vSwitch Deploy."
fi

