#!/bin/bash
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}

# generate_config & provisioning defaults
RELEASE_TYPE=${RELEASE_TYPE:-stable}
HOSTS_FILE=${HOSTS_FILE:-$(pwd)/data/$DEPLOY_NAME/kubernetes.env}

# vswitch defaults
PROJECT_ROOT=${PROJECT_ROOT:-$(cd ../ ; pwd -P)}
FACILITY=${FACILITY:-sjc1}
VLAN_SEGMENT=${VLAN_SEGMENT:-$DEPLOY_NAME}
PLAYBOOK=${PLAYBOOK:-k8s_worker_vswitch_quad_intel.yml}
KUBECONFIG=${KUBECONFIG:-$(pwd)/data/$DEPLOY_NAME/mycluster/artifacts/admin.conf}


if [ "$1" == "generate_config" ]; then
if ! [ -z ${MASTER_HOSTS+x} ] && ! [ -z ${WORKER_HOSTS+x} ]; then
   HOSTS_CMD="--master-hosts $MASTER_HOSTS --worker-hosts $WORKER_HOSTS"
elif ! [ -z ${HOSTS_FILE+x} ]; then
   HOSTS_TMP="/tmp$HOSTS_FILE"
   HOSTS_VOLUME="-v $HOSTS_FILE:"
   HOSTS_CMD="--hosts-file $HOSTS_TMP"
else
   echo 'No hosts were found, exiting'
fi
fi

# Generate Cluster-Config
if [ "$1" == "generate_config" ]; then
    CONFIG_FILE="$(pwd)/data/$DEPLOY_NAME/cluster.yml"
    if [ -f "$CONFIG_FILE" ]; then
       echo 'configuration for this deployment already exists, exiting'
       exit 1
    fi
docker run \
  --rm \
  -v $(pwd)/data/$DEPLOY_NAME:/k8s-infra/data \
  $HOSTS_VOLUME$HOSTS_TMP \
  -ti crosscloudci/k8s-infra:v1.0.0 \
  /k8s-infra/bin/k8sinfra generate_config ${HOSTS_CMD} --release-type=$RELEASE_TYPE -o /k8s-infra/data/cluster.yml
fi

#Provision Cluster
if [ "$1" == "provision" ]; then
    CLUSTER_DATA="$(pwd)/data/$DEPLOY_NAME/mycluster"
    if [ -d "$CLUSTER_DATA" ]; then
        echo 'cluster data for this deployment already exists, exiting'
        exit 1
    fi
docker run \
  --rm \
  -v $(pwd)/data/$DEPLOY_NAME:/k8s-infra/data \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -ti crosscloudci/k8s-infra:v1.0.0 \
  /k8s-infra/bin/k8sinfra provision --config-file=/k8s-infra/data/cluster.yml

if [ "$?" == "1" ]; then
   echo 'exit code 1 detected, provisioning failed'
else
   echo "Local System KUBECONFIG path: $(pwd)/data/$DEPLOY_NAME/mycluster/artifacts/admin.conf"
   # echo "To set fix permission errors run: chown $(whoami):$(whoami) $(pwd)/data/$DEPLOY_NAME -R"
fi
fi

#Provision vswitch
if [ "$1" == "vswitch" ]; then
    if ! [ -z ${WORKER_HOSTS+x} ]; then
        WORKER_IPS="$WORKER_HOSTS"
        WORKER_IPS_ARRAY=($(echo $WORKER_HOSTS | tr ',' ' '))
        WORKER_HOSTNAMES="$(for ((n=1;n<"${#WORKER_IPS_ARRAY[@]}";n++)); do echo -n $DEPLOY_NAME-worker$n,;done;echo -n $DEPLOY_NAME-worker"${#WORKER_IPS_ARRAY[@]}")"
    elif ! [ -z ${KUBECONFIG+x} ]; then
        WORKER_IPS_ARRAY=($(docker run -v $KUBECONFIG:/tmp/admin.conf -e KUBECONFIG=/tmp/admin.conf -ti bitnami/kubectl get no -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{range .status.addresses}}{{if (eq .type "InternalIP") }}{{.address}}{{" "}}{{end}}{{end}}{{end}}{{end}}'))
        WORKER_IPS="$(echo ${WORKER_IPS_ARRAY[@]} | tr ' ', ',')"
        WORKER_HOSTNAMES="$(for ((n=1;n<"${#WORKER_IPS_ARRAY[@]}";n++)); do echo -n $DEPLOY_NAME-worker$n,;done;echo -n $DEPLOY_NAME-worker"${#WORKER_IPS_ARRAY[@]}")"
    else
        echo 'No hosts were found, exiting'
    fi
docker run \
       --rm \
       -v "${PROJECT_ROOT}/comparison/ansible:/ansible" \
       -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
       -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
       -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
       -e PACKET_FACILITY=${FACILITY} \
       -e K8S_DEPLOY_ENV=${VLAN_SEGMENT} \
       -e ANSIBLE_HOST_KEY_CHECKING=False \
       --entrypoint=ansible-playbook \
       -ti cnfdeploytools:latest -i "${WORKER_IPS}," -e server_list="${WORKER_HOSTNAMES}" /ansible/$PLAYBOOK
fi


