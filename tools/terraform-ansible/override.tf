# Provision L2 Networking # TODO: delete this file, was only included in check in for debug

resource "packet_device" "master" {
  hardware_reservation_id = "next-available"
}

resource "packet_device" "worker" {
  hardware_reservation_id = "next-available"
}