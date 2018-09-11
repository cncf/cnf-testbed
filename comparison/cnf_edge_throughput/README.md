### CNF/VNF - Edge Network Max Throughput Comparison

Steps to Deploy.

1. Clone Repo ```git clone git@github.com:cncf/cnfs.git```
2. Enter terraform dir ```cnfs/comparison/cnf_edge_throughput/```
3. Run Docker container with API/Token vars set ```docker run -v $(pwd):/packet -e TF_VAR_packet_api_key=PACKET-API-KEY -e TF_VAR_packet_project_id=PACKET-PROJECT-ID --entrypoint=/bin/bash -ti hashicorp/terraform:full```
4. cd to packet dir ```cd /packet```
5. Terraform provision ``` terraform init && terraform apply```
