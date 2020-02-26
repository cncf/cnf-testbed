## Deploy GoGTP example with Multus on Kubernetes

This example use-case deploys the GoGTP service chain with Multus support on Kubernetes. The example includes two endpoints ("User Equipment" and "External Server") that can be used to test traffic through the GoGTP EPC implementation.

### Prerequisites
A Kubernetes cluster must be available prior to running this example. The cluster must be configured with Multus to provide additional interfaces to the pods in the service chain. 

A temporary fix must be applied to the tools/kubernetes_provisioning.sh script for Multus to work:
```
vim tools/kubernetes_provisioning.sh
```
Update line 54
```
-ti crosscloudci/k8s-infra:multus \
```

After the above changes have been made, setup the K8s pre-requisites by following the steps [here](https://github.com/cncf/cnf-testbed/tree/master/tools#pre-requisites), then provision a Kubernetes cluster using the steps [here](https://github.com/cncf/cnf-testbed/tree/master/tools#deploying-a-kubernetes-cluster-using-the-makefile--ci-tools).

### Installing the GoGTP service chain
The service chain is deployed using Helm. You will need to point the `KUBECONFIG` environment variable to your Kubeconfig file prior to running Helm. The steps can be seen below:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig

## Configure the bridges to be used with Multus to connect the pods
$ kubectl apply -f gogtp-bridges.yml

## Install the service chain
$ helm install ./gogtp/
```

Wait for approximately 30 seconds before checking that the eNB is running:
```
$ kubectl logs gogtp-enb
net.ipv4.ip_forward = 1 
[eNB] 2020/01/31 13:23:46 Established S1-MME connection with 172.21.1.12:36412
[eNB] 2020/01/31 13:23:46 Started serving S1-U on 172.21.0.11:2152
[eNB] 2020/01/31 13:23:46 Successfully established tunnel for 001010000000001
```

You should see output similar to what is shown below. If the log is empty wait a few more seconds and try again.

### Testing the GoGTP service chain
You can test the service chain by connecting from the "User Equipment" to the "External Server" using `wget`:
```
$ kubectl exec -it gogtp-ue /bin/bash
$$ wget http://10.0.1.201
```

You should see a successful HTTP request, followed by `index.html` being saved. You can also test the connection using `ping`:
```
$ kubectl exec -it gogtp-ue /bin/bash
$$ ping 10.0.1.201
PING 10.0.1.201 (10.0.1.201) 56(84) bytes of data. 
64 bytes from 10.0.1.201: icmp_seq=1 ttl=61 time=0.139 ms
64 bytes from 10.0.1.201: icmp_seq=2 ttl=61 time=0.126 ms
...
```

### Remove the GoGTP service chain and network bridges
Remove the GoGTP deployment using helm, and the network bridges using `kubectl` as shown below:
```
$ helm delete $(helm list | grep gogtp-0.1.0 | awk '{print $1}')
$ kubectl delete -f gogtp-briges.yml
```

