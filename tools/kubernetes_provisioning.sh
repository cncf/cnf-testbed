#!/bin/bash
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
if ! [ -z ${MASTER_HOSTS+x} ] && ! [ -z ${WORKER_HOSTS+x} ]; then
   HOSTS_CMD="--master-hosts $MASTER_HOSTS --worker-hosts $WORKER_HOSTS"
elif ! [ -z ${HOSTS_FILE+x} ]; then
   HOSTS_TMP="/tmp$HOSTS_FILE"
   HOSTS_VOLUME="-v $HOSTS_FILE:"
   HOSTS_CMD="--hosts-file $HOSTS_TMP"
else
   echo 'No hosts were found, exiting'
fi

docker run \
  --rm \
  -v $(pwd)/data:/data \
  $HOSTS_VOLUME$HOSTS_TMP \
  -ti crosscloudci/k8s-infra:v1.0.0 \
  /k8s-infra/bin/k8sinfra generate_config ${HOSTS_CMD} --release-type=$RELEASE_TYPE -o /data/$DEPLOY_NAME.yml
