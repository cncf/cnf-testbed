#!/bin/bash

kubectl create -f pgw.yml
kubectl create -f sgw.yml
sleep 5
PGW_IP=$(kubectl get pods gogtp-pgw -o jsonpath='{.status.podIP}')
SGW_IP=$(kubectl get pods gogtp-sgw -o jsonpath='{.status.podIP}')
kubectl create -f mme-configmap.yml
envsubst < mme.yml | kubectl create -f -
sleep 5
MME_IP=$(kubectl get pods gogtp-mme -o jsonpath='{.status.podIP}')
kubectl create -f enb-configmap.yml
envsubst < enb.yml | kubectl create -f -
