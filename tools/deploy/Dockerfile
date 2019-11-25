FROM golang:buster as golang
MAINTAINER "Denver Williams <denver@debian.nz>"

RUN apt install -y git make
RUN git clone https://github.com/denverwilliams/terraform-provisioner-ansible.git \
    $GOPATH/src/github.com/radekg/terraform-provisioner-ansible/ && \
    cd $GOPATH/src/github.com/radekg/terraform-provisioner-ansible/ && \
    make build-linux

FROM ubuntu:packet_api

ENV TERRAFORM_VERSION=0.12.2
ENV TERRAFORM_ANSIBLE=v2.0.1

#Install Terraform 
RUN apt update && \
    apt install -y software-properties-common && \ 
    apt-add-repository ppa:ansible/ansible -y && \
    apt update && \
    apt install -y git curl ansible unzip python-netaddr && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \ 
    ansible-galaxy install nickjj.docker && \ 
    ansible-galaxy install avinetworks.docker && \
    ansible-galaxy install mrlesmithjr.config-interfaces 
   
# Install infra-provisioning
RUN git clone https://github.com/crosscloudci/infra-provisioning.git /infra-provisioning \
    && cp -a /infra-provisioning/terraform /terraform \
    && cp /infra-provisioning/create_nodes.sh /terraform \
    && cd /terraform \
    && rm /terraform/s3-backend.tf \
    && rm /terraform/reserved_override \
    && terraform init
    

# Copy Terraform Ansible Plugin
RUN mkdir -p ~/.terraform.d/plugins/
COPY --from=golang /root/.terraform.d/plugins/terraform-provisioner-ansible /root/.terraform.d/plugins/terraform-provisioner-ansible

RUN mkdir -p /etc/ansible
COPY ansible.cfg /etc/ansible/ansible.cfg

WORKDIR /terraform
ENTRYPOINT ["/bin/terraform"]
