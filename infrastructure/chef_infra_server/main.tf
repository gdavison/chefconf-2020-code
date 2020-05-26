resource "aws_instance" "chef_infra_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  disable_api_termination = true

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
  }

  iam_instance_profile = var.iam_instance_profile

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "Chef Infra Server"
  }

  user_data = data.template_cloudinit_config.chef_infra_server.rendered
}

data "template_cloudinit_config" "chef_infra_server" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "package_upgrade: true"
  }
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOT
    #!/usr/bin/env bash
    temp_dir=$(mktemp -d)
    cd $${temp_dir}
    aws s3 cp s3://${var.repo_bucket}/chef-server.tgz .
    tar -xzvf chef-server.tgz
    jq --null-input --arg fqdn ${local.fqdn} --arg email ${var.chef_server_admin_email} '{"chef-server": {api_fqdn: $fqdn}, mcs: {managed_user: {email: $email}}}' > attributes.json
    #sudo chef-client --local-mode --chef-license accept-silent --json-attributes attributes.json
    EOT
  }
}

locals {
  # If we ever recreate the Chef Infra Server, put the trimsuffix here
  fqdn = "${var.host_name}.${var.zone.name}"
}

resource "aws_route53_record" "record" {
  zone_id = var.zone.zone_id
  name    = var.host_name
  type    = "A"
  ttl     = "30"
  records = [aws_instance.chef_infra_server.public_ip]
}

resource "aws_route53_record" "record_private" {
  zone_id = var.private_zone_id
  name    = var.host_name
  type    = "A"
  ttl     = "30"
  records = [aws_instance.chef_infra_server.private_ip]
}
