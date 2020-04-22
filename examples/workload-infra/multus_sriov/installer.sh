#! /bin/bash
if [ $# -eq 0 ]; then
  kubectl apply -f configmap.yaml -f sriovdp-daemonset-v3.2.yaml -f sriov-crd.yaml
elif [ "$1" == "del" ]; then
  kubectl delete -f sriov-crd.yaml -f sriovdp-daemonset-v3.2.yaml -f configmap.yaml
else
 echo "Usage: $0 [del]" 
fi
