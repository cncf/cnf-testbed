resource "packet_device" "cnfs" {
  count            = "${ var.packet_node_count }"
  hostname         = "${ var.name }${ count.index + 1 }"
  facility         = "${ var.packet_facility }"
  project_id       = "${ var.packet_project_id }"
  plan             = "${ var.packet_master_device_plan }"
  billing_cycle    = "${ var.packet_billing_cycle }"
  operating_system = "${ var.packet_operating_system }"
 
  connection {
    type     = "ssh"
    user     = "root"
    private_key = "${ file("/root/.ssh/id_rsa")}"
    timeout = "120m"
}
  
  provisioner "ansible" {
    plays {
      playbook ={
        file_path = "${ var.playbook }"
      }
    }
  }
}
