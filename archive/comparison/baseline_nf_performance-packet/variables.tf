provider "packet" {
  auth_token = "${ var.packet_api_key }"
}
variable "name" { default = "packet" }
variable "packet_node_count" { default = "4" }
variable "packet_project_id" {}
variable "packet_api_key" {}
variable "packet_facility" { default = "sjc1" }
variable "packet_billing_cycle" { default = "hourly" }

# VM Image and size
variable "packet_master_device_plan" { default = "m2.xlarge.x86" }
variable "packet_operating_system" { default = "201bc259-982b-41a1-a4c1-bba01ce71f51" }
