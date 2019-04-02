provider "packet" {
  auth_token = "${ var.packet_api_key }"
}
variable "master_name" { default = "pktmst" }
variable "packet_master_count" { default = "1" }
variable "name" { default = "pktnode" }
variable "packet_node_count" { default = "1" }
variable "packet_project_id" {}
variable "packet_api_key" {}
variable "packet_facility" { default = "sjc1" }
variable "packet_billing_cycle" { default = "hourly" }

# VM Image and size
variable "packet_master_device_plan" { default = "m2.xlarge.x86" }
variable "packet_node_device_plan" { default = "m2.xlarge.x86" }
variable "packet_operating_system" { default = "ubuntu_16_04" }

#Ansible
variable "playbook" {}
