#! /bin/bash
if [ $# -eq 0 ]; then
  kubectl apply -f multus-daemonset.yaml -f configmap.yaml -f sriovdp-daemonset.yaml -f sriov-crd.yaml
elif [ "$1" == "del" ]; then
  kubectl delete -f sriov-crd.yaml -f sriovdp-daemonset.yaml -f configmap.yaml -f multus-daemonset.yaml
else
 echo "Usage: $0 [del]" 
fi
