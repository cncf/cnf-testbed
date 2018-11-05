**Deploy a K8s cluster to Packet.net**

Set your Packet.net account project & api tokens.
Then run deploy_cluster.sh

```
export PACKET_PROJECT_ID=YOUR_PACKET_PROJECT_ID 
export PACKET_AUTH_TOKEN=YOUR_PACKET_API_KEY
./deploy_cluster.sh
```

After Provisioning has finished, to access the cluster withe kubectl.

```
export KUBECONFIG=$(pwd)/data/kubeconfig
kubectl get nodes
```

To Destroy the cluster run 
```
./destroy_cluster.sh
```
