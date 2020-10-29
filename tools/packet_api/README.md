## Equinix Metal layer-2 API utility

l2_packet_networking.rb

General options:
  - --server=<servername> => Equinix Metal hostname (from webui/api)
  - --instance-id=<instance id> => Equinix Metal instance ID (from webui/api)
  - --project-name=<CNCF CNFS> => Equinix Metal project name
  - --packet-url=<EQUINIX METAL URL> => Hostname for Equinix Metal API server

#### Vlans

VLAN IDs are created by [Equinix Metal](https://metal.equinix.com/) and returned to the end user.  A descriptive
name can be given when creating the VLAN and used to search for the VLAN via
the API.

*SHOW VLAN DEVICES*

Option(s):
- --show-vlan-devices <vlan description>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --show-vlan-devices watsonvlan1 --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1'
```

*SHOW PROJECT VLANS*

Option(s):
- --show-project-vlans <project>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --show-project-vlans --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1'
```

*SHOW SERVER PORTS*

Option(s):
- --show-server-ports <server name>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --show-server-ports layer2test-01 --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1'
```

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
- --assign-vlan-port <equinix metal interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
```

*ASSIGN VLAN ID*

Option(s):
- --assign-vlan-id <vlan id> => 
- --assign-vlan-port <equinix metal interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --assign-vlan-id 1100 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
```

*UNASSIGN VLAN*

Option(s):
- --unassign-vlan <vlan description> => 
- --unassign-vlan-port <equinix metal interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --unassign-vlan watsonvlan1 --unassign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
```

*UNASSIGN VLAN ID*

Option(s):
- --unassign-vlan-id <vlan id> => 
- --unassign-vlan-port <equinix metal interface>
- --facility <facility short name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --unassign-vlan 1100 --unassign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'
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

Add an Equinix Metal interface (port) to the default bond interface. The interface may not have the same name as the interface on the host.

Option(s): 
  - --bond-interace <interface name>

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --bond-interface eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net' 
```

*DISBOND INTERFACE*

Remove an Equinix Metal interface (port) from the default bond interface.

Option(s): 
  - --disbond-interace <interface name> => name of Equinix Metal interface (not what shows in the host)

Example:

```
ruby l2_packet_networking.rb --server layer2test-01 --disbond-interface eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net' 
```
