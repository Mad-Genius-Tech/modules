
locals {
  default_settings = {
    engine_version                 = "2.3"
    instance_type                  = "t3.small.search"
    instance_count                 = 1
    zone_awareness_enabled         = false
    availability_zone_count        = 2
    dedicated_master_enabled       = false
    dedicated_master_type          = "t3.small.search"
    dedicated_master_count         = 0
    warm_enabled                   = false
    warm_count                     = null
    warm_type                      = null
    encrypt_at_rest_enabled        = true
    node_to_node_encryption        = true
    security_options_enabled       = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_name               = "admin"
    ebs_enabled                    = true
    volume_type                    = "gp3"
    volume_size                    = 10
    iops                           = null
    throughput                     = null
    wildcard_domain                = true
    custom_endpoint                = ""
    enforce_https                  = true
    tls_security_policy            = "Policy-Min-TLS-1-2-2019-07"
    audit_logs_enabled             = false
    search_logs_enabled            = false
    index_logs_enabled             = false
    application_logs_enabled       = false
    retention_in_days              = 7
    iam_role_arns                  = []
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        zone_awareness_enabled   = true
        availability_zone_count  = 3
        instance_type            = "r6g.large.search"
        instance_count           = 3
        iops                     = 3000
        throughput               = 125
        dedicated_master_enabled = true
        dedicated_master_type    = "r6g.large.search"
        dedicated_master_count   = 3
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  opensearch_map = {
    for k, v in var.opensearch : k => {
      "create"                         = coalesce(lookup(v, "create", null), true)
      "identifier"                     = strcontains(module.context.id, k) ? module.context.id : "${module.context.id}-${k}"
      "engine_version"                 = try(coalesce(lookup(v, "engine_version", null), local.merged_default_settings.engine_version), local.merged_default_settings.engine_version)
      "instance_type"                  = try(coalesce(lookup(v, "instance_type", null), local.merged_default_settings.instance_type), local.merged_default_settings.instance_type)
      "instance_count"                 = try(coalesce(lookup(v, "instance_count", null), local.merged_default_settings.instance_count), local.merged_default_settings.instance_count)
      "zone_awareness_enabled"         = try(coalesce(lookup(v, "zone_awareness_enabled", null), local.merged_default_settings.zone_awareness_enabled), local.merged_default_settings.zone_awareness_enabled)
      "dedicated_master_enabled"       = try(coalesce(lookup(v, "dedicated_master_enabled", null), local.merged_default_settings.dedicated_master_enabled), local.merged_default_settings.dedicated_master_enabled)
      "dedicated_master_type"          = try(coalesce(lookup(v, "dedicated_master_type", null), local.merged_default_settings.dedicated_master_type), local.merged_default_settings.dedicated_master_type)
      "dedicated_master_count"         = try(coalesce(lookup(v, "dedicated_master_count", null), local.merged_default_settings.dedicated_master_count), local.merged_default_settings.dedicated_master_count)
      "warm_enabled"                   = try(coalesce(lookup(v, "warm_enabled", null), local.merged_default_settings.warm_enabled), local.merged_default_settings.warm_enabled)
      "warm_count"                     = try(coalesce(lookup(v, "warm_count", null), local.merged_default_settings.warm_count), local.merged_default_settings.warm_count)
      "warm_type"                      = try(coalesce(lookup(v, "warm_type", null), local.merged_default_settings.warm_type), local.merged_default_settings.warm_type)
      "encrypt_at_rest_enabled"        = try(coalesce(lookup(v, "encrypt_at_rest_enabled", null), local.merged_default_settings.encrypt_at_rest_enabled), local.merged_default_settings.encrypt_at_rest_enabled)
      "node_to_node_encryption"        = try(coalesce(lookup(v, "node_to_node_encryption", null), local.merged_default_settings.node_to_node_encryption), local.merged_default_settings.node_to_node_encryption)
      "security_options_enabled"       = try(coalesce(lookup(v, "security_options_enabled", null), local.merged_default_settings.security_options_enabled), local.merged_default_settings.security_options_enabled)
      "anonymous_auth_enabled"         = try(coalesce(lookup(v, "anonymous_auth_enabled", null), local.merged_default_settings.anonymous_auth_enabled), local.merged_default_settings.anonymous_auth_enabled)
      "internal_user_database_enabled" = try(coalesce(lookup(v, "internal_user_database_enabled", null), local.merged_default_settings.internal_user_database_enabled), local.merged_default_settings.internal_user_database_enabled)
      "master_user_name"               = try(coalesce(lookup(v, "master_user_name", null), local.merged_default_settings.master_user_name), local.merged_default_settings.master_user_name)
      "ebs_enabled"                    = try(coalesce(lookup(v, "ebs_enabled", null), local.merged_default_settings.ebs_enabled), local.merged_default_settings.ebs_enabled)
      "volume_type"                    = try(coalesce(lookup(v, "volume_type", null), local.merged_default_settings.volume_type), local.merged_default_settings.volume_type)
      "volume_size"                    = try(coalesce(lookup(v, "volume_size", null), local.merged_default_settings.volume_size), local.merged_default_settings.volume_size)
      "iops"                           = try(coalesce(lookup(v, "iops", null), local.merged_default_settings.iops), local.merged_default_settings.iops)
      "throughput"                     = try(coalesce(lookup(v, "throughput", null), local.merged_default_settings.throughput), local.merged_default_settings.throughput)
      "wildcard_domain"                = try(coalesce(lookup(v, "wildcard_domain", null), local.merged_default_settings.wildcard_domain), local.merged_default_settings.wildcard_domain)
      "custom_endpoint"                = try(coalesce(lookup(v, "custom_endpoint", null), local.merged_default_settings.custom_endpoint), local.merged_default_settings.custom_endpoint)
      "enforce_https"                  = try(coalesce(lookup(v, "enforce_https", null), local.merged_default_settings.enforce_https), local.merged_default_settings.enforce_https)
      "tls_security_policy"            = try(coalesce(lookup(v, "tls_security_policy", null), local.merged_default_settings.tls_security_policy), local.merged_default_settings.tls_security_policy)
      "audit_logs_enabled"             = try(coalesce(lookup(v, "audit_logs_enabled", null), local.merged_default_settings.audit_logs_enabled), local.merged_default_settings.audit_logs_enabled)
      "search_logs_enabled"            = try(coalesce(lookup(v, "search_logs_enabled", null), local.merged_default_settings.search_logs_enabled), local.merged_default_settings.search_logs_enabled)
      "index_logs_enabled"             = try(coalesce(lookup(v, "index_logs_enabled", null), local.merged_default_settings.index_logs_enabled), local.merged_default_settings.index_logs_enabled)
      "application_logs_enabled"       = try(coalesce(lookup(v, "application_logs_enabled", null), local.merged_default_settings.application_logs_enabled), local.merged_default_settings.application_logs_enabled)
      "retention_in_days"              = try(coalesce(lookup(v, "retention_in_days", null), local.merged_default_settings.retention_in_days), local.merged_default_settings.retention_in_days)
      "create"                         = try(coalesce(lookup(v, "create", null), true), true)
      "iam_role_arns"                  = distinct(compact(concat(coalesce(lookup(v, "iam_role_arns", null), local.merged_default_settings.iam_role_arns), local.merged_default_settings.iam_role_arns)))
      "availability_zone_count"        = try(coalesce(lookup(v, "availability_zone_count", null), local.merged_default_settings.availability_zone_count), local.merged_default_settings.availability_zone_count)
    } if coalesce(lookup(v, "create", null), true)
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_service_linked_role" "es" {
  count            = var.create_linked_role ? 1 : 0
  aws_service_name = var.aws_service_name_for_linked_role
}

data "aws_acm_certificate" "wildcard" {
  for_each = { for k, v in local.opensearch_map : k => v if v.create && v.wildcard_domain && length(v.custom_endpoint) > 0 }
  domain   = join(".", slice(split(".", each.value.custom_endpoint), length(split(".", each.value.custom_endpoint)) - 2, length(split(".", each.value.custom_endpoint))))
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "non_wildcard" {
  for_each = { for k, v in local.opensearch_map : k => v if v.create && !v.wildcard_domain && length(v.custom_endpoint) > 0 }
  domain   = each.value.custom_endpoint
  statuses = ["ISSUED"]
}

resource "random_password" "password" {
  for_each         = local.opensearch_map
  length           = 12
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = false
  override_special = "!"
}

resource "aws_secretsmanager_secret" "secret" {
  for_each = { for k, v in local.opensearch_map : k => v if var.enable_secret_manager && v.create }
  name     = "${var.org_name}-${var.stage_name}/opensearch/${each.value.identifier}"
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each = {
    for k, v in local.opensearch_map : k => {
      secret_id = aws_secretsmanager_secret.secret[k].id
      secret_string = jsonencode({
        "username" = v.master_user_name
        "password" = random_password.password[k].result
        "endpoint" = aws_opensearch_domain.opensearch[k].endpoint
        "uri"      = "https://${v.master_user_name}:${random_password.password[k].result}@${aws_opensearch_domain.opensearch[k].endpoint}"
      })
    } if var.enable_secret_manager && v.create
  }
  secret_id     = each.value.secret_id
  secret_string = each.value.secret_string
}

resource "aws_opensearch_domain" "opensearch" {
  for_each       = local.opensearch_map
  domain_name    = each.value.identifier
  engine_version = "OpenSearch_${each.value.engine_version}"

  cluster_config {
    dedicated_master_enabled = each.value.dedicated_master_enabled
    dedicated_master_type    = each.value.dedicated_master_type
    dedicated_master_count   = each.value.dedicated_master_count
    warm_enabled             = each.value.warm_enabled
    warm_count               = each.value.warm_count
    warm_type                = each.value.warm_type
    instance_type            = each.value.instance_type
    instance_count           = each.value.instance_count
    zone_awareness_enabled   = length(var.subnet_ids) > 1 && (each.value.instance_count % length(var.subnet_ids)) == 0 && each.value.zone_awareness_enabled ? true : false

    dynamic "zone_awareness_config" {
      for_each = length(var.subnet_ids) > 1 && (each.value.instance_count % length(var.subnet_ids)) == 0 && each.value.zone_awareness_enabled ? [true] : []
      content {
        availability_zone_count = each.value.availability_zone_count
      }
    }
  }

  encrypt_at_rest {
    enabled = each.value.encrypt_at_rest_enabled
  }

  node_to_node_encryption {
    enabled = each.value.node_to_node_encryption
  }

  advanced_security_options {
    enabled                        = each.value.security_options_enabled
    anonymous_auth_enabled         = each.value.anonymous_auth_enabled
    internal_user_database_enabled = each.value.internal_user_database_enabled
    master_user_options {
      master_user_name     = each.value.master_user_name
      master_user_password = random_password.password[each.key].result
    }
  }

  vpc_options {
    subnet_ids         = length(var.subnet_ids) > 1 && (each.value.instance_count % length(var.subnet_ids)) == 0 && each.value.zone_awareness_enabled ? var.subnet_ids : [var.subnet_ids[0]]
    security_group_ids = [module.opensearch_sg[each.key].security_group_id]
  }



  ebs_options {
    ebs_enabled = each.value.ebs_enabled
    volume_type = each.value.volume_type
    volume_size = each.value.volume_size
    iops        = each.value.iops
    throughput  = each.value.throughput
  }

  domain_endpoint_options {
    enforce_https                   = each.value.enforce_https
    tls_security_policy             = each.value.tls_security_policy
    custom_endpoint_enabled         = length(each.value.custom_endpoint) > 0 ? true : false
    custom_endpoint                 = length(each.value.custom_endpoint) > 0 ? each.value.custom_domain : null
    custom_endpoint_certificate_arn = length(each.value.custom_endpoint) > 0 ? (each.value.wildcard_domain ? data.aws_acm_certificate.wildcard[each.key].arn : data.aws_acm_certificate.non_wildcard[each.key].arn) : null
  }

  dynamic "log_publishing_options" {
    for_each = each.value.audit_logs_enabled ? [1] : []
    content {
      enabled                  = each.value.audit_logs_enabled
      log_type                 = "AUDIT_LOGS"
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_audit_logs[each.key].arn
    }
  }

  dynamic "log_publishing_options" {
    for_each = each.value.application_logs_enabled ? [1] : []
    content {
      enabled                  = each.value.application_logs_enabled
      log_type                 = "ES_APPLICATION_LOGS"
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_application_logs[each.key].arn
    }
  }

  dynamic "log_publishing_options" {
    for_each = each.value.index_logs_enabled ? [1] : []
    content {
      enabled                  = each.value.index_logs_enabled
      log_type                 = "INDEX_SLOW_LOGS"
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_index_slow_logs[each.key].arn
    }
  }

  dynamic "log_publishing_options" {
    for_each = each.value.search_logs_enabled ? [1] : []
    content {
      enabled                  = each.value.search_logs_enabled
      log_type                 = "SEARCH_SLOW_LOGS"
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_search_logs[each.key].arn
    }
  }

  access_policies = <<CONFIG
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "es:*",
              "Principal": "*",
              "Effect": "Allow",
              "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${each.value.identifier}/*"
          }
      ]
  }
  CONFIG

  tags = local.tags
}

data "aws_iam_policy_document" "iam_policy" {
  for_each = { for k, v in local.opensearch_map : k => v if length(v.iam_role_arns) > 0 }
  statement {
    effect  = "Allow"
    actions = ["es:*"]
    resources = [
      aws_opensearch_domain.opensearch[each.key].arn,
      "${aws_opensearch_domain.opensearch[each.key].arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = each.value.iam_role_arns
    }
  }
}

resource "aws_opensearch_domain_policy" "default" {
  for_each        = { for k, v in local.opensearch_map : k => v if length(v.iam_role_arns) > 0 }
  domain_name     = aws_opensearch_domain.opensearch[each.key].id
  access_policies = data.aws_iam_policy_document.iam_policy[each.key].json
}

module "opensearch_sg" {
  for_each    = local.opensearch_map
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.1.0"
  name        = "${each.value.identifier}-sg"
  description = "Opensearch ${each.value.identifier} Security group"
  vpc_id      = var.vpc_id
  computed_ingress_with_source_security_group_id = length(var.ingress_security_group_id) > 0 ? [
    {
      rule                     = "https-443-tcp"
      source_security_group_id = var.ingress_security_group_id
    }
  ] : []
  number_of_computed_ingress_with_source_security_group_id = length(var.ingress_security_group_id) > 0 ? 1 : 0
  computed_ingress_with_cidr_blocks = length(var.ingress_cidr_blocks) > 0 ? [
    {
      rule        = "https-443-tcp"
      cidr_blocks = join(",", var.ingress_cidr_blocks)
    }
  ] : []
  number_of_computed_ingress_with_cidr_blocks = length(var.ingress_cidr_blocks) > 0 ? 1 : 0
}


resource "aws_cloudwatch_log_group" "opensearch_audit_logs" {
  for_each          = { for k, v in local.opensearch_map : k => v if v.audit_logs_enabled }
  name              = "/aws/opensearch/${each.value.identifier}/audit-log"
  retention_in_days = each.value.retention_in_days
}

resource "aws_cloudwatch_log_group" "opensearch_index_slow_logs" {
  for_each          = { for k, v in local.opensearch_map : k => v if v.index_logs_enabled }
  name              = "/aws/opensearch/${each.value.identifier}/index-slow"
  retention_in_days = each.value.retention_in_days
}

resource "aws_cloudwatch_log_group" "opensearch_search_slow_logs" {
  for_each          = { for k, v in local.opensearch_map : k => v if v.search_logs_enabled }
  name              = "/aws/opensearch/${each.value.identifier}/search-slow"
  retention_in_days = each.value.retention_in_days
}

resource "aws_cloudwatch_log_group" "opensearch_application_logs" {
  for_each          = { for k, v in local.opensearch_map : k => v if v.application_logs_enabled }
  name              = "/aws/opensearch/${each.value.identifier}/application-log"
  retention_in_days = each.value.retention_in_days
}
