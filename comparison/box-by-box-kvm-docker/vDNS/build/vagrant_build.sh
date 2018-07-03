#!/bin/bash


mydir=$(dirname $0)

cd /build

echo "Installing software for vDNS"
sh ./v_dns_install.sh

echo "Setting up VM for vagrant box creation/saving"
sh ./inject_vagrant_ssh_key.sh
