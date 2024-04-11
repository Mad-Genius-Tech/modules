resource "tls_private_key" "user" {
  for_each  = var.vpn_users
  algorithm = "RSA"
}

resource "tls_cert_request" "user" {
  for_each        = var.vpn_users
  private_key_pem = tls_private_key.user[each.key].private_key_pem

  subject {
    common_name  = "${each.key}.vpn.client"
    organization = var.org_name
  }
}

resource "tls_locally_signed_cert" "user" {
  for_each           = var.vpn_users
  cert_request_pem   = tls_cert_request.user[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = coalesce(each.value.validity_period_hours, 87600)

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "aws_acm_certificate" "user" {
  for_each          = { for k, v in var.vpn_users : k => v if var.create }
  private_key       = tls_private_key.user[each.key].private_key_pem
  certificate_body  = tls_locally_signed_cert.user[each.key].cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem
}


locals {
  user_client_configuration = var.create ? { for k, v in var.vpn_users : k => templatefile("${path.module}/templates/client-config.ovpn.tpl", {
    original_client_config = replace(
      data.awsutils_ec2_client_vpn_export_client_config.client_vpn_config[0].client_configuration,
      "remote cvpn",
      "remote ${local.service_name}.cvpn"
    )
    cert        = tls_locally_signed_cert.user[k].cert_pem
    private_key = tls_private_key.user[k].private_key_pem
  }) } : {}
}

resource "local_file" "user_client_configuration" {
  for_each = var.create && var.enable_config_file ? local.user_client_configuration : {}
  content  = each.value
  filename = "${var.terragrunt_directory}/${each.key}-${local.service_name}.ovpn"
}


resource "local_file" "ca_key" {
  count    = var.create && var.enable_config_file ? 1 : 0
  content  = tls_private_key.ca.private_key_pem
  filename = "${var.terragrunt_directory}/ca.key"
}

resource "local_file" "ca_cert" {
  count    = var.create && var.enable_config_file ? 1 : 0
  content  = tls_self_signed_cert.ca.cert_pem
  filename = "${var.terragrunt_directory}/ca.crt"
}

resource "local_file" "users_cert" {
  for_each = var.create && var.enable_config_file ? var.vpn_users : {}
  content  = tls_locally_signed_cert.user[each.key].cert_pem
  filename = "${var.terragrunt_directory}/${each.key}.vpn.client.crt"
}
