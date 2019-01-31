# Provision L2 Networking 

# resource "packet_device" "workers" {
#   hardware_reservation_id = "bce65556-70ea-48c0-aa11-2c018ab9dcd7"
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