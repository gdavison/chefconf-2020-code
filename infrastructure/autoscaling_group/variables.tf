variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "iam_instance_profile" {
  type = string
}

variable "instance_security_group_ids" {
  type = set(string)
}

variable "loadbalancer_security_group_ids" {
  type = set(string)
}

variable "subnet_ids" {
  type = set(string)
}

variable "vpc_id" {
  type = string
}

variable "chef_infra_server_url" {
  type = string
}

variable "chef_automate_server_url" {
  type = string
}

variable "inspec_runner_ssm_document_name" {
  type = string
}
