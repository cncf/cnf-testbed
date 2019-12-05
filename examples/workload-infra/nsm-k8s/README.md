# K8s cluster with NSM deployed and ready to use

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

Note: in case of `Error: no available release name found` do (according to [helm issue](https://github.com/helm/helm/issues/4412)):

```
$ kubectl create serviceaccount --namespace kube-system tiller
$ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
$ kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```


### Installing NSM
Install NSM by running the following command from this directory:
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm repo add nsm https://helm.nsm.dev/
$ helm install nsm/nsm --name=nsm --values=values.yaml
```

### Deleting NSM
Run the following command:
```
$ helm delete --purge nsm
```

