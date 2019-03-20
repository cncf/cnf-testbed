# using defaults including on demand systems
resource "packet_device" "cnfs" {
  connection {}
  provisioner "local-exec" {
    command = "echo 'skip ansible plugin'"
  }
}

