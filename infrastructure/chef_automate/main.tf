resource "aws_instance" "automate_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  disable_api_termination = true

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 15
  }

  iam_instance_profile = var.iam_instance_profile

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "Chef Automate"
  }

  user_data = data.template_cloudinit_config.automate_server.rendered
}

data "template_cloudinit_config" "automate_server" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "package_upgrade: true"
  }
}

locals {
  fqdn = "${var.host_name}.${var.zone.name}"
}

resource "aws_route53_record" "record" {
  zone_id = var.zone.zone_id
  name    = var.host_name
  type    = "A"
  ttl     = "30"
  records = [aws_instance.automate_server.public_ip]
}

resource "aws_route53_record" "record_private" {
  zone_id = var.private_zone_id
  name    = var.host_name
  type    = "A"
  ttl     = "30"
  records = [aws_instance.automate_server.private_ip]
}
