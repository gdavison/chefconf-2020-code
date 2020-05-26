output "public_ip" {
  value = aws_instance.chef_infra_server.public_ip
}

output "private_ip" {
  value = aws_instance.chef_infra_server.private_ip
}

output "server_fqdn" {
  value = trimsuffix(local.fqdn, ".")
}
