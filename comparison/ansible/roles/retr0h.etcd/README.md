etcd
====

A role which installs and manages a clustered etcd.

Role ready status
-----------------

[![Build Status](http://img.shields.io/travis/retr0h/ansible-etcd.svg?style=flat-square)](https://travis-ci.org/retr0h/ansible-etcd)
[![Galaxy](http://img.shields.io/badge/galaxy-ansible--etcd-blue.svg?style=flat-square)](https://galaxy.ansible.com/list#/roles/1206)

Requirements
------------

* Ansible 2.1
* Rsync
* SSL libraries
* IProute2

Role Variables
--------------

In order to accommodate a variety of different OSes, ansible-etcd uses a set of OS-family
specific variable files located in /var.  These files are included selectively when you run
the default playbook.  As a result, if you would like to deploy to multiple different OS families,
you need to call the playbook multiple times, as the playbook includes variables only for the
first detected OS.

Dependencies
------------

There are no dependencies of ansible-etcd.  If you are deploying to CoreOS, however, it is assumed
that you have already bootstapped python per [coreos-bootstrap](https://github.com/defunctzombie/ansible-coreos-bootstrap).

Example Playbook
----------------

    - hosts: redhat-hosts
      roles:
        - retr0h.etcd

    - hosts: debian-hosts
      roles:
        - retr0h.etcd

Testing
-------

Tests are performed by [Molecule](http://molecule.readthedocs.org/en/latest/).

    $ make
    $ source venv/bin/activate
    $ molecule test

License
-------

MIT
