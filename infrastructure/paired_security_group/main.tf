resource "aws_security_group_rule" "from" {
  security_group_id = var.source_security_group_id

  type                     = "egress"
  protocol                 = var.protocol
  from_port                = var.port
  to_port                  = var.port
  source_security_group_id = var.destination_security_group_id
}

resource "aws_security_group_rule" "to" {
  security_group_id = var.destination_security_group_id

  type                     = "ingress"
  protocol                 = var.protocol
  from_port                = var.port
  to_port                  = var.port
  source_security_group_id = var.source_security_group_id
}
