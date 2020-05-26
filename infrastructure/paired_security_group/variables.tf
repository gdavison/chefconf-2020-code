variable "source_security_group_id" {
  type = string
}

variable "destination_security_group_id" {
  type = string
}

variable "protocol" {
  type    = string
  default = "tcp"
}

variable "port" {
  type = number
}
