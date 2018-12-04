resource "null_resource" "worker_etcd_extra" {
  count = "${ var.worker_node_count }"

  provisioner "local-exec" {
    when = "create"
    on_failure = "fail"
    command = <<EOF
    #Worker Public Record
    curl -XPUT http://"${ var.etcd_server }"/v2/keys/skydns/local/"${ var.cloud_provider }"/"${ var.name }"/"${ var.name }-workerpub-${ count.index +1 }" \
    -d value='{"host":"${ element(split(",", var.public_worker_ips), count.index) }"}'
EOF
  }
}
