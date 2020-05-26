output "chef_infra_server_ip" {
  value = module.chef_infra_server.public_ip
}

output "chef_repo_archives_bucket_name" {
  value = aws_s3_bucket.chef_repo_archives.bucket
}
