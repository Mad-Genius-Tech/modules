output "security_group_id" {
  value = var.create ? aws_security_group.sg[0].id : null
}

output "vpn_endpoint_id" {
  value = var.create ? aws_ec2_client_vpn_endpoint.client_vpn_endpoint[0].id : null
}

output "vpn_endpoint_dns_name" {
  value = var.create ? aws_ec2_client_vpn_endpoint.client_vpn_endpoint.*.dns_name : null
}

output "vpn_endpoint_name" {
  value = var.create ? "${local.service_name}.${replace(aws_ec2_client_vpn_endpoint.client_vpn_endpoint.*.dns_name[0], "*.", "")}" : null
}

output "vpn_client_cert" {
  value = var.create ? tls_locally_signed_cert.root.cert_pem : null
}

output "vpn_client_key" {
  value     = var.create ? tls_private_key.root.private_key_pem : null
  sensitive = true
}

output "vpn_server_cert" {
  value = var.create ? tls_locally_signed_cert.server.cert_pem : null
}

output "vpn_server_key" {
  value     = var.create ? tls_private_key.server.private_key_pem : null
  sensitive = true
}

output "vpn_ca_cert" {
  value = var.create ? tls_self_signed_cert.ca.cert_pem : null
}

output "vpn_ca_key" {
  value     = var.create ? tls_private_key.ca.private_key_pem : null
  sensitive = true
}
