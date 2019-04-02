resource "packet_device" "master" {
  count            = "${ var.packet_master_count }"
  hostname         = "${ var.master_name }${ count.index + 1 }"
  facility         = "${ var.packet_facility }"
  project_id       = "${ var.packet_project_id }"
  plan             = "${ var.packet_master_device_plan }" # Packet.net machine type
  billing_cycle    = "${ var.packet_billing_cycle }" # hourly or monthly
  operating_system = "${ var.packet_operating_system }"
  public_ipv4_subnet_size = "30"
 
  connection {
    type     = "ssh"
    user     = "root"
    private_key = "${ file("/root/.ssh/id_rsa")}"
  }
  
  provisioner "ansible" {
    plays {
      playbook ={
        file_path = "${ var.playbook }"
      }
    }
  }
}
resource "packet_device" "worker" {
  count            = "${ var.packet_node_count }"
  hostname         = "${ var.name }${ count.index + 1 }"
  facility         = "${ var.packet_facility }"
  project_id       = "${ var.packet_project_id }"
  plan             = "${ var.packet_node_device_plan }" # Packet.net machine type
  billing_cycle    = "${ var.packet_billing_cycle }" # hourly or monthly
  operating_system = "${ var.packet_operating_system }"
  public_ipv4_subnet_size = "30"
 
  connection {
    type     = "ssh"
    user     = "root"
    private_key = "${ file("/root/.ssh/id_rsa")}"
  }
  
  provisioner "ansible" {
    plays {
      playbook ={
        file_path = "${ var.playbook }"
      }
    }
  }
}
