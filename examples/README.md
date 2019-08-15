Examples are broken up based on the layers in an environment running a use case
- hardware infra - eg. packet machines
- workload infra - eg. k8s + nsm, k8s + multus, openstack + vpp-networking
- service chains - Combines CNFs to provide a set of services. eg. hardware gateway + firewall + packet filter
- use cases - combine 1 or more service chains with a specific workload and hardware infra configuration

Examples should be aim to be composable with other examples (especially between layers)
