resource "aws_autoscaling_group" "web_sample" {
  name = "web-sample"

  desired_capacity = 1
  min_size         = 0
  max_size         = 2

  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.web_sample.id
    version = "$Latest"
  }

  health_check_type = "EC2"

  target_group_arns = [aws_lb_target_group.web_sample.arn]

  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_launch_template" "web_sample" {
  name = "web-sample"

  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = var.instance_security_group_ids

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  credit_specification {
    cpu_credits = "standard"
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "volume"]
    iterator = type
    content {
      resource_type = type.value
      tags = {
        Name = "Web Sample"
      }
    }
  }

  user_data = data.template_cloudinit_config.web_sample.rendered
}

data "template_cloudinit_config" "web_sample" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.chef_bootstrap.rendered
  }
}

data "template_file" "chef_bootstrap" {
  template = file("${path.module}/chef-bootstrap.sh.tpl")
  vars = {
    chef_infra_server_url    = var.chef_infra_server_url
    chef_automate_server_url = "https://${var.chef_automate_server_url}/data-collector/v0/"
  }
}

resource "aws_lb" "web_sample" {
  name               = "web-sample"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.loadbalancer_security_group_ids
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "web_sample" {
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "web_sample" {
  load_balancer_arn = aws_lb.web_sample.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_sample.arn
  }
}
