## Deploy GoGTP example with CPU Manager for Kubernetes (CMK) and Multus on Kubernetes

This example use-case deploys the GoGTP service chain with CMK and Multus support on Kubernetes. The example includes two endpoints ("User Equipment" and "External Server") that can be used to test traffic through the GoGTP EPC implementation.

This example utilizes CPU affinity (pinning) through CMK. By default the EPC workloads will have 2 cores (4 threads), while the Client/Server endpoints each have 1 core (2 threads). In addition the workloads are spread across both sockets on the server:
```
Socket 0: Client, eNB, MME, SGW
Socket 1: Server, PGW
```

### Prerequisites
A Kubernetes cluster must be available prior to running this example, and CPU isolation must be installed for the worker nodes in the cluster. Steps for installing and configuring this can be found [here](/tools)

Once the cluster is prepared, CMK must be installed using the cpu-manager example. Installation details can be found [here](/examples/workload-infra/cpu-manager)

### Configuration
While most of the default configuration should not be changed (unless you know what you are doing), it is possible to do some modifications to the deployment.

In the [gogtp/values.yaml](gogtp/values.yaml) file, you can modify `cpu:cores/socket` to change the CPU affinity and socket placement of the individual components. Note that the default CMK configuration supports 11 cores on each socket, and going beyond that will cause the example to fail.

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

