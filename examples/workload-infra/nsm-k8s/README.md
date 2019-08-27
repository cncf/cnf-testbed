## Install NSM on an existing Kubernetes deployment

This example is used to install NSM ([Network Service Mesh](https://networkservicemesh.io/))

### Prerequisites
A Kubernetes deployment must be avaialble prior to installing NSM.

You should have a `kubeconfig` file ready on the machine used for installing NSM.

Install Helm on the machine. The steps included here are taken from [helm.sh](https://helm.sh/docs/using_helm/#from-script):
```
$ curl -LO https://git.io/get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```
A few other optional steps you can decide if you need:
```
## Remove the downloaded script
$ rm get_helm.sh
## If you have a version mismatch between server and client
$ helm init --upgrade
```

### Installing NSM
Install NSM by running the following command from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm install --namespace=nsm-system nsm/
```
