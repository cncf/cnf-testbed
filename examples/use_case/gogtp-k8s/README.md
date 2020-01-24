## Deploy GoGTP example on Kubernetes

This example use-case deploys the GoGTP service chain on Kubernetes. 

### Prerequisites
A Kubernetes cluster must be available prior to running this example.

You should have a `kubeconfig` file ready on the machine, as it is used to deploy the example on a worker node.

Helm must be installed prior to installing this example. The steps listed below are based on [https://helm.sh](https://helm.sh/docs/using_helm/#from-script)
```
$ curl -LO https://git.io/get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
$ helm init --service-account tiller

## You might need to run the below if versions are mismatched
  $ helm init --upgrade
```

### Installing the GoGTP service chain
The service chain is deployed using Helm. You will need to point the `KUBECONFIG` environment variable to your Kubeconfig file prior to running Helm. The steps can be seen below:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm install ./gogtp/
```

### Limitations
Using a basic Kubernetes deployment, the networking capabilities are limietd. As a results of this all pods in the service chain communicate though the shared localhost interface (127.0.0.0/8).

As all pods are sharing the same network, no endpoints (Client, Server) are created for this example. While the endpoints can be created, there is no separtion between them, so communication will happen directly between them, instead of through the GoGTP service chain.
