provider "aws" {
  version = "~>2.58"
}

data "aws_region" "current" {}

locals {
  chef_success_account_id = "446539779517"
}

locals {
  http_port  = 80
  https_port = 443
}

locals {
  my_ip_cidr = "${var.my_ip}/32"
}

resource "aws_security_group" "baseline" {
  name   = "baseline"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "s3_access" {
  security_group_id = aws_security_group.baseline.id
  description       = "Access to S3 VPC Endpoint"

  type            = "egress"
  protocol        = "tcp"
  from_port       = local.https_port
  to_port         = local.https_port
  prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
}

resource "aws_security_group_rule" "yum_access" {
  security_group_id = aws_security_group.baseline.id
  description       = "Needed to access yum repos"

  for_each         = toset([for x in [local.http_port, local.https_port] : tostring(x)])
  type             = "egress"
  protocol         = "tcp"
  from_port        = each.value
  to_port          = each.value
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group" "chef_infra_server" {
  name   = "chef-infra-server"
  vpc_id = aws_vpc.main.id
}

# https://docs.chef.io/runbook/server_firewalls_and_ports/#standalone
resource "aws_security_group_rule" "chef_infra_https_from_home" {
  security_group_id = aws_security_group.chef_infra_server.id
  description       = "HTTPS from home"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = local.https_port
  to_port     = local.https_port
  cidr_blocks = [local.my_ip_cidr]
}

resource "aws_security_group_rule" "chef_infra_https_from_web_sample" {
  security_group_id = aws_security_group.chef_infra_server.id
  description       = "HTTPS from Web-Sample"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.https_port
  to_port                  = local.https_port
  source_security_group_id = aws_security_group.web_sample_instance.id
}

resource "aws_security_group" "chef_automate" {
  name   = "chef-automate"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "chef_automate_https_from_home" {
  security_group_id = aws_security_group.chef_automate.id
  description       = "HTTPS from home"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = local.https_port
  to_port     = local.https_port
  cidr_blocks = [local.my_ip_cidr]
}

resource "aws_security_group_rule" "chef_automate_https_from_infra_server" {
  security_group_id = aws_security_group.chef_automate.id
  description       = "HTTPS from Chef Infra Server"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.https_port
  to_port                  = local.https_port
  source_security_group_id = aws_security_group.chef_infra_server.id
}

resource "aws_security_group" "web_sample_instance" {
  name   = "web-sample-instance"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "web_sample_lb" {
  name   = "web-sample-lb"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "web_sample_http_from_home" {
  security_group_id = aws_security_group.web_sample_lb.id
  description       = "HTTP from home"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = local.http_port
  to_port     = local.http_port
  cidr_blocks = [local.my_ip_cidr]
}

module "web_sample_http" {
  source = "./paired_security_group"

  source_security_group_id      = aws_security_group.web_sample_lb.id
  destination_security_group_id = aws_security_group.web_sample_instance.id
  port                          = local.http_port
}

# This should have its own security group, not be part of web_sample_instance
module "automate_data_collector" {
  source = "./paired_security_group"

  source_security_group_id      = aws_security_group.web_sample_instance.id
  destination_security_group_id = aws_security_group.chef_automate.id
  port                          = local.https_port
}
