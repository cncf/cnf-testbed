#!/bin/bash

if [ -f "images/vnf_base.raw" ]; then
  echo "Removing old image from images/"
  rm -rf images/vnf*
fi

export ARCH="amd64"
export BASE_ELEMENTS="bootloader cloud-init-datasources ubuntu vnf"
export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive"
export DIB_DEV_USER_USERNAME=ubuntu
export DIB_DEV_USER_PASSWORD=ubuntu
export DIB_DEV_USER_PWDLESS_SUDO=Y
export DIB_RELEASE="bionic"
export ELEMENTS_PATH="./elements/"
export IMAGE_PATH="./images/vnf_base"
 
disk-image-create vm $BASE_ELEMENTS -t raw -o $IMAGE_PATH

if [ -f "images/vnf_base.raw" ]; then
  echo ""
  echo "Build Succesful"
  echo "Add image to openstack:"
  echo "openstack image create --disk-format qcow2 --container-format bare --public --file images/vnf_base.raw vnf_base"
fi
