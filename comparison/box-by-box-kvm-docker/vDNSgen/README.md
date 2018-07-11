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

# vDNS Packet Generator CNF

Works similar to VNF

### CNF setup/testing

Configuration and test done using All-In-One script:

`./run_container_test.sh`

### Notes

vDNSgen container is currently not limited in terms of CPU.
The VPP instance is limited to 3 cores (1 main and 2 workers).

The vDNS container should be running before using the AIO script. 
