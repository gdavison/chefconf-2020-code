output "public_ip" {
  value = aws_instance.automate_server.public_ip
}

output "private_ip" {
  value = aws_instance.automate_server.private_ip
}

output "server_fqdn" {
  value = trimsuffix(local.fqdn, ".")
}
