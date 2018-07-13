# vDNS VNF/CNF comparison

The VNF/CNF is using Bind9 and Kea DHCP

The setup scripts are originally from https://github.com/onap/demo/blob/master/vnfs/vCPE/scripts

### VNF setup

`vagrant up`

### CNF setup


Setup network (only once per host):
`docker network create --subnet=40.30.20.0/24 dns-net`

- Verify with `docker network ls`

Create the container (without starting it):
`docker create --privileged --name vDNS -t vdns`

Attach the second network to the container:
`docker network connect dns-net --ip 40.30.20.110 vDNS`

Start the container:
`docker start vDNS`


