## Helm chart for installing example VPP CNFs

This Helm chart can be used to install any number of pods running containerized VPP. In addition to the pods, the chart will also deploy a host bridge through Multus, with each pod attaching to the bridge with an interface that is available in VPP.

### Installing the example VPP CNFs
By default a single pod will be deployed. If more are needed, update `vpp/values.yaml` with additional entries under `cnf` (an example for a second CNF is included, but commented).

By default, VPP will enable the bridge interface added to the pod. If additional configuration is needed, update `vpp/templates/configmap.yaml` with the necessary CLI commands.

Once everything is configured, install the VPP CNFs using the below commands
```
## set environment variable for KUBECONFIG (replace path to match your location)
$ export KUBECONFIG=<path>/<to>/kubeconfig
$ helm install ./vpp/
```
