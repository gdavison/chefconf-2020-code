data "aws_route53_zone" "parent" {
  name = var.parent_domain_name
}

locals {
  domain_name = "chef-conf.${var.parent_domain_name}"
}

resource "aws_route53_zone" "chef_conf" {
  name = local.domain_name
}

resource "aws_route53_record" "chef_conf_ns" {
  zone_id = data.aws_route53_zone.parent.zone_id
  name    = local.domain_name
  type    = "NS"
  ttl     = "3600"

  records = aws_route53_zone.chef_conf.name_servers
}

resource "aws_route53_zone" "chef_conf_private" {
  name = local.domain_name

  vpc {
    vpc_id = aws_vpc.main.id
  }
}
