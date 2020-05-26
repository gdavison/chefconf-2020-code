data "aws_ami" "centos" {
  most_recent = true
  owners      = [local.chef_success_account_id]

  filter {
    name   = "name"
    values = ["chef-highperf-centos7-*"]
  }
}

module "chef_infra_server" {
  source = "./chef_infra_server"

  ami_id        = data.aws_ami.centos.id
  instance_type = "t3a.small"

  iam_instance_profile = aws_iam_instance_profile.chef_infra_server.name

  subnet_id = aws_subnet.main[0].id
  security_group_ids = [
    aws_security_group.chef_infra_server.id,
    aws_security_group.baseline.id,
  ]

  zone            = aws_route53_zone.chef_conf
  host_name       = "server"
  private_zone_id = aws_route53_zone.chef_conf_private.id

  repo_bucket = aws_s3_bucket.chef_repo_archives.bucket

  chef_server_admin_email = var.chef_server_admin_email
}

module "chef_automate" {
  source = "./chef_automate"

  ami_id        = data.aws_ami.centos.id
  instance_type = "t3a.medium"

  iam_instance_profile = aws_iam_instance_profile.chef_infra_server.name

  subnet_id = aws_subnet.main[0].id
  security_group_ids = [
    aws_security_group.chef_automate.id,
    aws_security_group.baseline.id,
  ]

  zone            = aws_route53_zone.chef_conf
  host_name       = "automate"
  private_zone_id = aws_route53_zone.chef_conf_private.id
}

module "autoscaling_group" {
  source = "./autoscaling_group"

  ami_id        = data.aws_ami.centos.id
  instance_type = "t3a.micro"

  iam_instance_profile = aws_iam_instance_profile.chef_infra_server.name

  vpc_id = aws_vpc.main.id
  instance_security_group_ids = [
    aws_security_group.web_sample_instance.id,
    aws_security_group.baseline.id,
  ]
  loadbalancer_security_group_ids = [
    aws_security_group.web_sample_lb.id,
  ]
  subnet_ids = aws_subnet.main[*].id

  chef_infra_server_url    = module.chef_infra_server.server_fqdn
  chef_automate_server_url = module.chef_automate.server_fqdn

  inspec_runner_ssm_document_name = aws_ssm_document.inspec_runner.name
}
