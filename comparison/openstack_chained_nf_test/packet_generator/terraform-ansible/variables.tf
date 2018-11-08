provider "packet" {
  auth_token = "${ var.packet_api_key }"
}
variable "name" { default = "os-host" }
variable "packet_node_count" { default = "4" }
variable "packet_project_id" {}
variable "packet_api_key" {}
variable "packet_facility" { default = "ewr1" }
variable "packet_billing_cycle" { default = "hourly" }

# VM Image and size
variable "packet_master_device_plan" { default = "c1.xlarge.x86" }
variable "packet_operating_system" { default = "centos_7" }

#Ansible
variable "playbook" {}
variable "vlan" { default= ["1137","1138"] }
