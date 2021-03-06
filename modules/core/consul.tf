# --------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# --------------------------------------------------------------------------------------------------

locals {
  consul_http_api_port = 8500
}

module "consul_servers" {
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-cluster?ref=v0.3.5"

  cluster_name  = "${var.consul_cluster_name}"
  cluster_size  = "${var.consul_cluster_size}"
  instance_type = "${var.consul_instance_type}"

  vpc_id        = "${var.vpc_id}"
  subnet_ids    = "${var.consul_subnets}"
  http_api_port = "${local.consul_http_api_port}"

  ssh_key_name                = "${var.ssh_key_name}"
  allowed_inbound_cidr_blocks = "${concat(list(data.aws_vpc.this.cidr_block), var.consul_allowed_inbound_cidr_blocks)}"
  allowed_ssh_cidr_blocks     = "${var.allowed_ssh_cidr_blocks}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  # Add this tag to each node in the cluster
  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.consul_cluster_name}"

  ami_id    = "${var.consul_ami_id}"
  user_data = "${coalesce(var.consul_user_data, data.template_file.user_data_consul_server.rendered)}"

  root_volume_type = "${var.consul_root_volume_type}"
  root_volume_size = "${var.consul_root_volume_size}"

  health_check_type    = "ELB"
  termination_policies = "${var.consul_termination_policies}"
}

# --------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER EC2 INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# --------------------------------------------------------------------------------------------------

data "template_file" "user_data_consul_server" {
  template = "${file("${path.module}/user_data/user-data-consul-server.sh")}"

  vars {
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.consul_cluster_name}"

    consul_prefix = "${var.integration_consul_prefix}"
  }
}
