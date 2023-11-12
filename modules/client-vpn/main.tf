locals {
  service_name = module.context.id
}

resource "aws_ec2_client_vpn_endpoint" "client_vpn_endpoint" {
  count                  = var.create ? 1 : 0
  description            = local.service_name
  server_certificate_arn = aws_acm_certificate.server[0].arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = true
  self_service_portal    = "disabled"
  security_group_ids     = [aws_security_group.sg[0].id]
  vpc_id                 = var.vpc_id

  client_login_banner_options {
    enabled     = true
    banner_text = local.service_name
  }

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.root[0].arn
  }

  connection_log_options {
    enabled               = var.enable_log
    cloudwatch_log_group  = length(aws_cloudwatch_log_group.vpn) > 0 ? aws_cloudwatch_log_group.vpn[0].name : null
    cloudwatch_log_stream = length(aws_cloudwatch_log_stream.vpn) > 0 ? aws_cloudwatch_log_stream.vpn[0].name : null
  }

  tags = merge({ "Name" = local.service_name }, local.tags)
}

resource "aws_ec2_client_vpn_network_association" "subnet_association" {
  count                  = var.create ? length(var.subnets) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn_endpoint[0].id
  subnet_id              = element(var.subnets, count.index)
}

resource "aws_ec2_client_vpn_authorization_rule" "authorization_rule" {
  count                  = var.create ? length(var.subnets_cidr_blocks) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn_endpoint[0].id
  target_network_cidr    = var.subnets_cidr_blocks[count.index]
  authorize_all_groups   = true
}

resource "aws_security_group" "sg" {
  count       = var.create ? 1 : 0
  name_prefix = local.service_name
  description = "security group allowing egress for ${local.service_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    protocol    = "UDP"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming VPN connection"
  }

  tags = merge({ "Name" = local.service_name }, local.tags)
}

resource "aws_security_group_rule" "egress" {
  count             = var.create ? 1 : 0
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg[0].id
}

resource "aws_cloudwatch_log_group" "vpn" {
  count             = var.create && var.enable_log ? 1 : 0
  name              = "/aws/vpn/${local.service_name}/logs"
  retention_in_days = var.logs_retention_in_days
  tags              = merge({ "Name" = "${local.service_name}-log" }, local.tags)
}

resource "aws_cloudwatch_log_stream" "vpn" {
  count          = var.create && var.enable_log ? 1 : 0
  name           = "${local.service_name}-usage"
  log_group_name = aws_cloudwatch_log_group.vpn[0].name
}

data "awsutils_ec2_client_vpn_export_client_config" "client_vpn_config" {
  count = var.create ? 1 : 0
  id    = aws_ec2_client_vpn_endpoint.client_vpn_endpoint[0].id
}

locals {
  full_client_configuration = var.create ? templatefile("${path.module}/templates/client-config.ovpn.tpl", {
    original_client_config = replace(
      data.awsutils_ec2_client_vpn_export_client_config.client_vpn_config[0].client_configuration,
      "remote cvpn",
      "remote ${local.service_name}.cvpn"
    )
    cert        = tls_locally_signed_cert.root.cert_pem
    private_key = tls_private_key.root.private_key_pem
  }) : ""
}

resource "local_file" "full_client_configuration" {
  count    = var.create && var.enable_config_file ? 1 : 0
  content  = local.full_client_configuration
  filename = "${var.terragrunt_directory}/vpn-${local.service_name}.ovpn"
}