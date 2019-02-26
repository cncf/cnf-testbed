# Provision L2 Networking 

resource "packet_device" "cnfs" {
  hardware_reservation_id = "next-available"
}