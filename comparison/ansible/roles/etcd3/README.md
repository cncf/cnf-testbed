# Install etcd3 through Ansible for Portworx

## Sample Playbook

Here is a sample playbook, that uses the `etcd3` role

```
---
- hosts: all
  remote_user: root
  vars:
       members: "{{ groups['nodes'] }}"
       etcd_version: "3.3.8"
  roles:
     - ../ansible-portworx-etcd3
```

## Samples Inventory

```
[nodes]
test1 IP=70.0.136.31
test2 IP=70.0.136.33
test3 IP=70.0.136.34
```

## Sample Run

[root@PDC2-SM10-N7 ansible-portworx-etcd3]# ansible-playbook -i inv.yml play.yml

PLAY [all] *********************************************************************

TASK [setup] *******************************************************************
ok: [test1]
ok: [test3]
ok: [test2]

TASK [../ansible-portworx-etcd3 : Remove any old existing etcd] ****************
ok: [test2]
ok: [test3]
ok: [test1]

TASK [../ansible-portworx-etcd3 : Remove any old existing etcd2] ***************
ok: [test1]
ok: [test3]
ok: [test2]

TASK [../ansible-portworx-etcd3 : install the latest version of wget] **********
changed: [test2]
changed: [test3]
changed: [test1]

TASK [../ansible-portworx-etcd3 : Set up persistent directory] *****************
changed: [test3]
 [WARNING]: Consider using file module with state=directory rather than running mkdir

changed: [test2]
changed: [test1]

TASK [../ansible-portworx-etcd3 : Install new etcd] ****************************
changed: [test2]
 [WARNING]: Consider using get_url or uri module rather than running wget

changed: [test1]
changed: [test3]

TASK [../ansible-portworx-etcd3 : template] ************************************
changed: [test2]
changed: [test3]
changed: [test1]

TASK [../ansible-portworx-etcd3 : Reload and start the services] ***************
changed: [test3]
changed: [test1]
changed: [test2]

PLAY RECAP *********************************************************************
test1                      : ok=8    changed=5    unreachable=0    failed=0
test2                      : ok=8    changed=5    unreachable=0    failed=0
test3                      : ok=8    changed=5    unreachable=0    failed=0

[root@PDC2-SM10-N7 ansible-portworx-etcd3]# curl http://70.0.137.72:2379/version
{"etcdserver":"3.3.8","etcdcluster":"3.3.0"}

```
