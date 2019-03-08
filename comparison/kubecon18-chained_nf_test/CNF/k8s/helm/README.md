## Running CNFs on K8s using Helm
Prior to deploying CNFs a worker node must be avaialble, deployed using using tools provided [HERE](https://github.com/cncf/cnf-testbed/tree/master/tools)

Ensure that KUBECONFIG is set as an environment variable
```
export KUBECONFIG=<Path_to_kubeconfig>
```

Verify that a node is available
```
kubectl get nodes
kubectl describe node
```

Update `config_{csc,csp}.sh` with MAC addresses from the packet generator
```
    trex_mac1=<MAC_address_left>
    trex_mac2=<MAC_address_right>
```

### Deploy CSP chains

Use the provided *run_csp.sh* script to deploy one or more CSP (Pipeline) chains
```
./run_csp.sh <Chains> <Nodes per chain> [clean]
```
* For 1-3 chains, VPP running in the host on the k8s node will be automatically updated
  - With more than 3 chains the configuration must be updated manually
* Existing chains can be removed by appending `clean` to the end of the command (see above)
  - <Chains> and <Nodes per chain> must still be provided when doing a cleanup

### Deploy CSC chains

Use the provided *run_csc.sh* script to deploy one or more CSC (Snake) chains
```
./run_csc.sh <Chains> <Nodes per chain> [clean]
```
* VPP running in the host on the k8s node will be automatically updated
* Existing chains can be removed by appending `clean` to the end of the command (see above)
  - <Chains> and <Nodes per chain> must still be provided when doing a cleanup
