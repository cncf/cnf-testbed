# K8s cluster with NSM deployed and ready to use

## Install NSM on an existing Kubernetes deployment

This example is used to install NSM ([Network Service Mesh](https://networkservicemesh.io/))

### Prerequisites
A Kubernetes deployment must be avaialble prior to installing NSM.

You should have a `kubeconfig` file ready on the machine used for installing NSM.

Install Helm on the machine. The steps included here are taken from [https://helm.sh](https://helm.sh/docs/intro/install/)
```
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh

## You might need to run the below if versions are mismatched
  $ helm init --upgrade
```

### Installing NSM
Install NSM by running the following command from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm repo add nsm https://helm.nsm.dev/
$ helm install nsm nsm/nsm --values=values.yaml
```

### Deleting NSM
Run the following command:
```
$ helm delete --purge nsm
```

