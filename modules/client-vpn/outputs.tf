output "security_group_id" {
  value = var.create ? aws_security_group.sg[0].id : null
}

output "vpn_endpoint_id" {
  value = var.create ? (var.authentication_type == "federated-authentication" ? aws_ec2_client_vpn_endpoint.saml[0].id : aws_ec2_client_vpn_endpoint.mtls[0].id) : null
}

output "vpn_endpoint_dns_name" {
  value = var.create ? (var.authentication_type == "federated-authentication" ? aws_ec2_client_vpn_endpoint.saml.*.dns_name : aws_ec2_client_vpn_endpoint.mtls.*.dns_name) : null
}

output "vpn_endpoint_name" {
  value = var.create ? (var.authentication_type == "federated-authentication" ? "${local.service_name}.${replace(aws_ec2_client_vpn_endpoint.saml.*.dns_name[0], "*.", "")}" : "${local.service_name}.${replace(aws_ec2_client_vpn_endpoint.mtls.*.dns_name[0], "*.", "")}") : null
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

output "self_service_url" {
  value = var.create && var.authentication_type == "federated-authentication" ? "https://self-service.clientvpn.amazonaws.com/endpoints/${aws_ec2_client_vpn_endpoint.saml[0].id}" : null
}
