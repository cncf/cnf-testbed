#! /bin/bash
if [ $# -eq 0 ]; then
  kubectl apply -f cmk-namespace.yaml -f cmk-rbac-rules.yaml -f cmk-serviceaccount.yaml -f cmk-cluster-init-pod.yaml
elif [ "$1" == "del" ]; then
  kubectl delete -f cmk-cluster-init-pod.yaml -f cmk-serviceaccount.yaml -f cmk-rbac-rules.yaml -f cmk-namespace.yaml
else
  echo "Usage: $0 [del]"
fi  
