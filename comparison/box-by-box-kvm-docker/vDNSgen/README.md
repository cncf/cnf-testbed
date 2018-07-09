# vDNS Packet Generator VNF

Uses the VPP packet-generator to send DNS messages towards the vDNS VNF

The setup scripts are originally from https://github.com/onap/demo/blob/master/vnfs/vCPE/scripts

### VNF VM setup/testing

`vagrant up`

### Starting the packet generator

SSH to the VNF

`vagrant ssh vDNSgen`

Start the vDNS test

`sudo ./vDNSgen/dns_test.sh`
