module "master_templates" {
    source = "/cncf/master_templates-v1.10.0-ubuntu"
}

module "worker_templates" {
    source = "../worker_templates-v1.10.0-ubuntu"
}

#resource "packet_device" "masters" {
#  hardware_reservation_id = "your-reservation_id"
#}

#resource "packet_device" "workers" {
#  hardware_reservation_id = "your-reservation_id"
#}


