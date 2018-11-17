module "master_templates" {
    source = "/cncf/master_templates-v1.10.0-ubuntu"
}

module "worker_templates" {
    source = "../worker_templates-v1.10.0-ubuntu"
}

#resource "packet_device" "masters" {
#  hardware_reservation_id = "your-reservation_id"
#}


# Provision L2 Networking 

# resource "packet_device" "workers" {
  # TODO: exclude by reservation ids, tag, hostname
  #       or include a set of reservation ids
  #       then use next-available
  # hardware_reservation_id = "d211457b-ee32-4abc-a218-8334a1879e08"
  # provisioner "ansible" {
  #   plays {
  #     playbook ={
  #       file_path = "${ var.playbook }"
  #     }
  #     extra_vars = {
  #       extra = {
  #         variables = {
  #           server_list = "${ join(",", packet_device.workers.*.hostname) }"
  #         }
  #       }
  #     }
  #   }
  # }
# }


