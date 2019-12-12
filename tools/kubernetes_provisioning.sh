#!/bin/bash
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
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
    CONFIG_FILE="$(pwd)/data/$DEPLOY_NAME.yml"
    if [ -f "$CONFIG_FILE" ]; then
       echo 'configuration for this deployment already exists, exiting'
       exit 1
    fi
docker run \
  --rm \
  -v $(pwd)/data/$DEPLOY_NAME:/k8s-infra/data \
  $HOSTS_VOLUME$HOSTS_TMP \
  -ti crosscloudci/k8s-infra:v1.0.0 \
  /k8s-infra/bin/k8sinfra generate_config ${HOSTS_CMD} --release-type=$RELEASE_TYPE -o /k8s-infra/data/$DEPLOY_NAME.yml
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
  /k8s-infra/bin/k8sinfra provision --config-file=/k8s-infra/data/$DEPLOY_NAME.yml

if [ "$?" == "1" ]; then
   echo 'exit code 1 detected, provisioning failed'
else
   echo "Local System KUBECONFIG path: $(pwd)/data/$DEPLOY_NAME/mycluster/artifacts/admin.conf"
   echo "To set fix permission run: chown $(whoami):$(whoami) $(pwd)/data/$DEPLOY_NAME -R"
fi
fi
