variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "iam_instance_profile" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = set(string)
}

variable "zone" {
  type = object({
    zone_id = string
    name    = string
  })
}

variable "host_name" {
  type = string
}

variable "private_zone_id" {
  type = string
}

variable "repo_bucket" {
  type = string
}

variable "chef_server_admin_email" {
  type = string
}
