output "public_ip" {
  description = "List of IDs of instances"
  value       =  "${aws_instance.web.public_ip}"
}

output "elastic_ip" {
  description = "The eip assigned"
  value       =  "${aws_eip.elastic_ip.public_ip}"
}

output "private_ssh_key" {
  description = "The private ssh key generated"
  value       =  "${tls_private_key.andrew_development_key.private_key_pem}"
}