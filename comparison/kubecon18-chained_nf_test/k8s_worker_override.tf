# Provision L2 Networking 

resource "packet_device" "workers" {
  hardware_reservation_id = "next-available"
}

output "server_list" {
  value = "${ join(",", packet_device.workers.*.hostname) }"
}
