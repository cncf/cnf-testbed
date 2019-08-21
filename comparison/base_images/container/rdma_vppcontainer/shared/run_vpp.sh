#! /bin/bash
vpp -c /etc/vpp/startup.conf 2>&1 | tee /etc/vpp/output.log
