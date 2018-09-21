#! /bin/bash

mydir=$(dirname $0)
cd $mydir

if [ "$#" -ne 2 ]; then
    echo "ERROR: Script expects to arguments"
    echo "Usage: $0 VLAN#1 VLAN#2" 
fi

if [ ! -d "VPP_configs/orig" ]; then
  mkdir VPP_configs/orig
  cp VPP_configs/vEdge_cnf.conf VPP_configs/orig/vEdge_cnf.conf
  cp VPP_configs/vEdge_vnf.conf VPP_configs/orig/vEdge_vnf.conf
fi

cp VPP_configs/orig/vEdge_cnf.conf VPP_configs/vEdge_cnf.conf
cp VPP_configs/orig/vEdge_vnf.conf VPP_configs/vEdge_vnf.conf

sed -i "s/1070/${1}/g" VPP_configs/vEdge_cnf.conf
sed -i "s/1070/${1}/g" VPP_configs/vEdge_vnf.conf

sed -i "s/1064/${2}/g" VPP_configs/vEdge_cnf.conf
sed -i "s/1064/${2}/g" VPP_configs/vEdge_vnf.conf

echo "Updated VLANs to ${1} and ${2}"
exit 0
