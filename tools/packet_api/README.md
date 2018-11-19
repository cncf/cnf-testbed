## Packet layer-2 API utility

l2_packet_networking.rb

General options:
  - --server=<servername> => Packet hostname (from webui/api)
  - --instance-id=<instance id> => Packet instance ID (from webui/api)
  - --project-name=<CNCF CNFS> => Packet project name
  - --packet-url=<PACKET URL> => Hostname for Packet API server

#### Vlans

VLAN IDs are created by Packet and returned to the end user.  A descriptive
name can be given when creating the VLAN and used to search for the VLAN via
the API.

*CREATE VLAN*

Option(s):
- --create-vlan <vlan description>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1'
```

*ASSIGN VLAN*

Option(s):
- --assign-vlan <vlan description> => 
- --assign-vlan-port <packet interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
```

*ASSIGN VLAN ID*

Option(s):
- --assign-vlan-id <vlan id> => 
- --assign-vlan-port <packet interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --assign-vlan-id 1100 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
```

*UNASSIGN VLAN*

Option(s):
- --unassign-vlan <vlan description> => 
- --unassign-vlan-port <packet interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --unassign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
```

*UNASSIGN VLAN ID*

Option(s):
- --unassign-vlan-id <vlan id> => 
- --unassign-vlan-port <packet interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --unassign-vlan 1100 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
```

*DELETE VLAN*

Option(s):
- --delete-vlan <vlan description>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --delete-vlan watsonvlan1 --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1'
```

#### Bond interfaces


*BOND INTERFACE*

Add a Packet interface (port) to the Packet default bond interface. The Packet interface may not have the same name as the interface on the host.

Option(s): 
  - --bond-interace <interface name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --bond-interface eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net' 
```

*DISBOND INTERFACE*

Remove a Packet interface (port) from the default Packet bond interface.

Option(s): 
  - --disbond-interace <interface name> => name of Packet interface (not what shows in the host)

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --disbond-interface eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net' 
```
