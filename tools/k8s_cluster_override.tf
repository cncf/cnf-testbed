module "master_templates" {
    source = "/cncf/master_templates-v1.13.0-ubuntu"
}

module "worker_templates" {
    source = "../worker_templates-v1.13.0-ubuntu"
}
