# ONS Demo Notes

## K8s benchmark
The below assumes that K8s is deployed using the provided Ansible scripts on a server equipped with Intel (x710) NIC. The result should be at least 1 worker node with VPP running in the host with interfaces showing up in VPP. The NF configuration that is used for benchmarks is 3 chains of 2 nodes.
The default configuration uses 2 ports, each configured with 1 VLAN (Access mode). An alternative configuration has been used for comparing to Openstack, which uses 1 port configured with 2 VLANs (Trunk mode).

### Demo configuration
For the ONS presentation and demo, the following setup is used:
* Traffic generator: "packetgen-intel" ("quad3)
  - Ext IP: 147.75.105.103
  - NIC: Intel x710
  - VLANs: 1076 (eth2), 1078 (eth3)

* K8s worker: "k8s-ons-intel-worker-1.k8s-ons-intel.packet.local"
  - Ext IP: 147.75.65.73
  - NIC: Intel x710
  - VLANs (Default): 1076 (eth1), 1078 (eth2)
  - VLANs (1 Port): 1076 (eth1), 1078 (eth1)

### Switching to containerized host VPP
Start by stopping and disabling the vpp service running on the worker host.
```
service vpp stop
systemctl disable vpp.service
```
Then, on the server used for deploying (e.g. 'pair'), ensure that the KUBECONFIG environment variable has been set, and deploy the VPP container using the provided Helm chart.
```
export KUBECONFIG=/path/to/kubeconfig
cd /<CNF Testbed root>/comparison/baseline_nf_performance-packet/host_vpp_container/helm
helm install --name hostvpp ./VPPcontainer/
```
Verify that the container is running using kubectl, then SSH to the K8s worker node and verify the state and configuration of VPP.
```
ssh <K8s worker>
docker exec -it $(docker ps | grep soelvkaer | awk '{print $1}') /bin/bash
vppctl
show int
```
The configuration should look similar to the below.
```
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet1a/0/1          1      up          9200/0/0/0
TenGigabitEthernet1a/0/2          2      up          9200/0/0/0
local0                            0     down          0/0/0/0
memif1/1                          3      up          9000/0/0/0
memif2/2                          4      up          9000/0/0/0
memif3/3                          5      up          9000/0/0/0
memif4/4                          6      up          9000/0/0/0
memif5/5                          7      up          9000/0/0/0
memif6/6                          8      up          9000/0/0/0
```

### Switching from 2 to 1 port configuration
Start by changing the Network configuration for the server (through app.packet.net). Change the Layer 2 configuration to use the following VLAN configuration
* 1076 (eth1), 1078 (eth1)

Once the layer 2 infrastructure has been modified, log in to the VPP container running on the worker node.
```
docker exec -it $(docker ps | grep soelvkaer | awk '{print $1}') /bin/bash
```

In the container, start by modifying the entrypoint script to use a different startup configuration.
Edit the file /tmp/run_vpp.sh, and change the last line `vpp -c /tmp/vpp_config/startup.conf` so use a different filename (chose one that doesn't already exist in /tmp/vpp_config/ to avoid it being replaced during container restart).
Start out by copying the existing startup to the new filename, i.e. `cp /tmp/vpp_config/startup.conf /tmp/vpp_config/<new_startup>`. In the new file, do the following modifications. Note that a new setup file is required, and as with the startup file, select a filename that doesn't already exist to prevent it being replaced.
```
@@ -4,7 +4,7 @@
   full-coredump
   cli-listen /run/vpp/cli.sock
   gid vpp
-  startup-config /tmp/vpp_config/setup.gate
+  startup-config /tmp/vpp_config/<new_setup_file>
 }

 api-trace {
@@ -26,9 +26,9 @@

 dpdk {
   dev default {
-    num-rx-queues 2
+    num-rx-queues 4
   }
-  dev 0000:1a:00.1 dev 0000:1a:00.2
+  dev 0000:1a:00.1
   no-multi-seg
   no-tx-checksum-offload
   socket-mem 124,0
```

In the new setup file, add the following content:
(CSP - Pipeline case)
```
create bridge-domain 1
create bridge-domain 2

bin memif_socket_filename_add_del add id 1 filename /etc/vpp/sockets/memif1.sock
bin memif_socket_filename_add_del add id 2 filename /etc/vpp/sockets/memif2.sock
bin memif_socket_filename_add_del add id 3 filename /etc/vpp/sockets/memif3.sock
bin memif_socket_filename_add_del add id 4 filename /etc/vpp/sockets/memif4.sock
bin memif_socket_filename_add_del add id 5 filename /etc/vpp/sockets/memif5.sock
bin memif_socket_filename_add_del add id 6 filename /etc/vpp/sockets/memif6.sock

create interface memif id 1 socket-id 1 master
create interface memif id 2 socket-id 2 master
create interface memif id 3 socket-id 3 master
create interface memif id 4 socket-id 4 master
create interface memif id 5 socket-id 5 master
create interface memif id 6 socket-id 6 master

set int state TenGigabitEthernet1a/0/1 up
create sub TenGigabitEthernet1a/0/1 1076
create sub TenGigabitEthernet1a/0/1 1078

set interface l2 tag-rewrite TenGigabitEthernet1a/0/1.1076 pop 1
set interface l2 tag-rewrite TenGigabitEthernet1a/0/1.1078 pop 1

set int l2 bridge TenGigabitEthernet1a/0/1.1076 1
set int l2 bridge memif1/1 1
set int l2 bridge memif3/3 1
set int l2 bridge memif5/5 1
set int l2 bridge TenGigabitEthernet1a/0/1.1078 2
set int l2 bridge memif2/2 2
set int l2 bridge memif4/4 2
set int l2 bridge memif6/6 2

set int mtu 9200 TenGigabitEthernet1a/0/1

set int state TenGigabitEthernet1a/0/1.1076 up
set int state TenGigabitEthernet1a/0/1.1078 up
set int state memif1/1 up
set int state memif2/2 up
set int state memif3/3 up
set int state memif4/4 up
set int state memif5/5 up
set int state memif6/6 up
```

(CSC - Snake case)
```
create bridge-domain 1
create bridge-domain 2
create bridge-domain 3
bin memif_socket_filename_add_del add id 1 filename /etc/vpp/sockets/memif1.sock
create interface memif id 1 socket-id 1 master
bin memif_socket_filename_add_del add id 2 filename /etc/vpp/sockets/memif2.sock
create interface memif id 2 socket-id 2 master
bin memif_socket_filename_add_del add id 3 filename /etc/vpp/sockets/memif3.sock
create interface memif id 3 socket-id 3 master
bin memif_socket_filename_add_del add id 4 filename /etc/vpp/sockets/memif4.sock
create interface memif id 4 socket-id 4 master
bin memif_socket_filename_add_del add id 5 filename /etc/vpp/sockets/memif5.sock
create interface memif id 5 socket-id 5 master
bin memif_socket_filename_add_del add id 6 filename /etc/vpp/sockets/memif6.sock
create interface memif id 6 socket-id 6 master
bin memif_socket_filename_add_del add id 7 filename /etc/vpp/sockets/memif7.sock
create interface memif id 7 socket-id 7 master
bin memif_socket_filename_add_del add id 8 filename /etc/vpp/sockets/memif8.sock
create interface memif id 8 socket-id 8 master
bin memif_socket_filename_add_del add id 9 filename /etc/vpp/sockets/memif9.sock
create interface memif id 9 socket-id 9 master
bin memif_socket_filename_add_del add id 10 filename /etc/vpp/sockets/memif10.sock
create interface memif id 10 socket-id 10 master
bin memif_socket_filename_add_del add id 11 filename /etc/vpp/sockets/memif11.sock
create interface memif id 11 socket-id 11 master
bin memif_socket_filename_add_del add id 12 filename /etc/vpp/sockets/memif12.sock
create interface memif id 12 socket-id 12 master

set int state TenGigabitEthernet1a/0/1 up
create sub TenGigabitEthernet1a/0/1 1076
create sub TenGigabitEthernet1a/0/1 1078

set interface l2 tag-rewrite TenGigabitEthernet1a/0/1.1076 pop 1
set interface l2 tag-rewrite TenGigabitEthernet1a/0/1.1078 pop 1

set int l2 bridge TenGigabitEthernet1a/0/1.1076 1
set int l2 bridge memif1/1 1
set int l2 bridge memif2/2 2
set int l2 bridge memif3/3 2
set int l2 bridge memif4/4 3
set int l2 bridge memif5/5 1
set int l2 bridge memif6/6 2
set int l2 bridge memif7/7 2
set int l2 bridge memif8/8 3
set int l2 bridge memif9/9 1
set int l2 bridge memif10/10 2
set int l2 bridge memif11/11 2
set int l2 bridge memif12/12 3
set int l2 bridge TenGigabitEthernet1a/0/1.1078 3

set int mtu 9200 TenGigabitEthernet1a/0/1

set int state TenGigabitEthernet1a/0/1.1076 up
set int state TenGigabitEthernet1a/0/1.1078 up
set int state memif1/1 up
set int state memif2/2 up
set int state memif3/3 up
set int state memif4/4 up
set int state memif5/5 up
set int state memif6/6 up
set int state memif7/7 up
set int state memif8/8 up
set int state memif9/9 up
set int state memif10/10 up
set int state memif11/11 up
set int state memif12/12 up
```

Once the configuration has been updated, exit the container and restart it:
```
docker restart $(docker ps | grep soelvkaer | awk '{print $1}')
```

### 2 port CSC (Snake case) configuration
Currently only CSP (Pipeline case) configurations are included in the container by default. For running a 3 chain 2 nodes configuration with CSC, use the following configuration.
```
create bridge-domain 1
create bridge-domain 2
create bridge-domain 3
bin memif_socket_filename_add_del add id 1 filename /etc/vpp/sockets/memif1.sock
create interface memif id 1 socket-id 1 master
bin memif_socket_filename_add_del add id 2 filename /etc/vpp/sockets/memif2.sock
create interface memif id 2 socket-id 2 master
bin memif_socket_filename_add_del add id 3 filename /etc/vpp/sockets/memif3.sock
create interface memif id 3 socket-id 3 master
bin memif_socket_filename_add_del add id 4 filename /etc/vpp/sockets/memif4.sock
create interface memif id 4 socket-id 4 master
bin memif_socket_filename_add_del add id 5 filename /etc/vpp/sockets/memif5.sock
create interface memif id 5 socket-id 5 master
bin memif_socket_filename_add_del add id 6 filename /etc/vpp/sockets/memif6.sock
create interface memif id 6 socket-id 6 master
bin memif_socket_filename_add_del add id 7 filename /etc/vpp/sockets/memif7.sock
create interface memif id 7 socket-id 7 master
bin memif_socket_filename_add_del add id 8 filename /etc/vpp/sockets/memif8.sock
create interface memif id 8 socket-id 8 master
bin memif_socket_filename_add_del add id 9 filename /etc/vpp/sockets/memif9.sock
create interface memif id 9 socket-id 9 master
bin memif_socket_filename_add_del add id 10 filename /etc/vpp/sockets/memif10.sock
create interface memif id 10 socket-id 10 master
bin memif_socket_filename_add_del add id 11 filename /etc/vpp/sockets/memif11.sock
create interface memif id 11 socket-id 11 master
bin memif_socket_filename_add_del add id 12 filename /etc/vpp/sockets/memif12.sock
create interface memif id 12 socket-id 12 master

set int state TenGigabitEthernet1a/0/1 up
set int state TenGigabitEthernet1a/0/2 up

set int l2 bridge TenGigabitEthernet1a/0/1 1
set int l2 bridge memif1/1 1
set int l2 bridge memif2/2 2
set int l2 bridge memif3/3 2
set int l2 bridge memif4/4 3
set int l2 bridge memif5/5 1
set int l2 bridge memif6/6 2
set int l2 bridge memif7/7 2
set int l2 bridge memif8/8 3
set int l2 bridge memif9/9 1
set int l2 bridge memif10/10 2
set int l2 bridge memif11/11 2
set int l2 bridge memif12/12 3
set int l2 bridge TenGigabitEthernet1a/0/2 3

set int mtu 9200 TenGigabitEthernet1a/0/1
set int mtu 9200 TenGigabitEthernet1a/0/2

set int state TenGigabitEthernet1a/0/1 up
set int state TenGigabitEthernet1a/0/2 up
set int state memif1/1 up
set int state memif2/2 up
set int state memif3/3 up
set int state memif4/4 up
set int state memif5/5 up
set int state memif6/6 up
set int state memif7/7 up
set int state memif8/8 up
set int state memif9/9 up
set int state memif10/10 up
set int state memif11/11 up
set int state memif12/12 up
```
To use the configuration update `/tmp/run_vpp.sh` in the container, so that it points to a new startup file (with a name that doesn't exist), then copy the default startup.conf file to the new filename, and update the startup-config to the file where you saved the above interface configuration. Once that is done restart the container and verify that the configuration is correct. Also make sure that the layer 2 infrastructure configuration for the server is using 2 ports, each with 1 vlan (see details above).

### Creating the network functions
On the server used for deploying, change to the directory `<CNF Testbed root>/comparison/baseline_nf_performance-packet/host_vpp_container/helm`. In that directory, use the following commands to create and delete NFs:

**Note: For the ONS demo/presentation, use "pair" server and `~/src/michaelp/cnfs/comparison/kubecon18-chained_nf_test/CNF/k8s/helm` as the directory for running the below scripts (see note in block below)**
```
# Create or delete CSP containers
./run_csp.sh 3 2 [clean]
# Create or delete CSC containers
./run_csc.sh 3 2 [clean]
  # I added a temporary skip to this file: "HOST_VPP_CONTAINER=true", as the script normally fetches VLAN info from target
```

Verify with `kubectl` or `helm` that containers are created or deleted.

### Running the traffic generator (NFVbench)
SSH to the server running the traffic generator, and change directory to `~/pktgen`. The "packetgen-intel" already has the correct configuration, so the only changes that might be needed are benchmark related. Edit `run_test_nfvbench.sh` and update `RATES`, `ITERATIONS` and `DURATION` if changes are needed. There are additional parameters that can be changed (i.e. CHAINS, NODES and PREFIX), but these are only used when generating the output filenames.

More detailed settings for NFVbench can be found in `~/nfvbench_config.sh`. It is currently configured to run tests against a 3 chain 2 nodes setup, using VLANs 1076 and 1078. If changes are needed they can either be done directly in this file, or the file can be copied to a new filename and modified. If the latter method is used the new filename must be updated in the run script (~/pktgen/run_test_nfvbench.sh).

Once everything is configured the benchmark can be run as follows (from ~/pktgen)
```
./run_test_nfvbench.sh [chains] [nodes] [prefix]
```
The three input variables are optional and only used to modify the output filenames without modifying the script.
Traffic should start after a few seconds. If NFVbench keeps checking for connectivity there is likely an issue with the configuration of the K8s worker node (Layer 2 infrastructure of host VPP). Verify that configurations are correct and try again.

NFVbench can be restarted by restarting the container
```
docker restart nfvbench
```
