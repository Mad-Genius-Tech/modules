
locals {
  default_settings = {
    version                      = "14.6"
    min_capacity                 = 1
    max_capacity                 = 64
    master_username              = "postgres"
    skip_final_snapshot          = true
    backup_retention_period      = 1
    performance_insights_enabled = false
    monitoring_interval          = 0
    database_name                = null
    deletion_protection          = false
    lambda_functions             = []
    instances_count              = 1
    instances                    = {}
    enable_cloudwatch_alarm      = false
    alarms = {
      "statistic"               = "Average"
      "namespace"               = "AWS/RDS"
      "comparison_operator"     = "GreaterThanOrEqualToThreshold"
      "dimensions"              = {}
      "cloudwatch_alarm_action" = ""
    }
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        skip_final_snapshot          = false
        backup_retention_period      = 7
        performance_insights_enabled = true
        monitoring_interval          = 60
        deletion_protection          = true
        instances_count              = 2
        enable_cloudwatch_alarm      = true
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  aurora_map = {
    for k, v in var.aurora : k => {
      "create"                       = coalesce(lookup(v, "create", null), true)
      "identifier"                   = "${module.context.id}-${k}"
      "version"                      = try(coalesce(lookup(v, "version", null), local.merged_default_settings.version), local.merged_default_settings.version)
      "min_capacity"                 = try(coalesce(lookup(v, "min_capacity", null), local.merged_default_settings.min_capacity), local.merged_default_settings.min_capacity)
      "max_capacity"                 = try(coalesce(lookup(v, "max_capacity", null), local.merged_default_settings.max_capacity), local.merged_default_settings.max_capacity)
      "master_username"              = try(coalesce(lookup(v, "master_username", null), local.merged_default_settings.master_username), local.merged_default_settings.master_username)
      "skip_final_snapshot"          = try(coalesce(lookup(v, "skip_final_snapshot", null), local.merged_default_settings.skip_final_snapshot), local.merged_default_settings.skip_final_snapshot)
      "backup_retention_period"      = try(coalesce(lookup(v, "backup_retention_period", null), local.merged_default_settings.backup_retention_period), local.merged_default_settings.backup_retention_period)
      "performance_insights_enabled" = try(coalesce(lookup(v, "performance_insights_enabled", null), local.merged_default_settings.performance_insights_enabled), local.merged_default_settings.performance_insights_enabled)
      "monitoring_interval"          = try(coalesce(lookup(v, "monitoring_interval", null), local.merged_default_settings.monitoring_interval), local.merged_default_settings.monitoring_interval)
      "database_name"                = try(coalesce(lookup(v, "database_name", null), local.merged_default_settings.database_name), local.merged_default_settings.database_name)
      "deletion_protection"          = try(coalesce(lookup(v, "deletion_protection", null), local.merged_default_settings.deletion_protection), local.merged_default_settings.deletion_protection)
      "lambda_functions"             = coalesce(lookup(v, "lambda_functions", null), local.merged_default_settings.lambda_functions)
      "instances_count"              = try(coalesce(lookup(v, "instances_count", null), local.merged_default_settings.instances_count), local.merged_default_settings.instances_count)
      "instances"                    = try(coalesce(lookup(v, "instances", null), local.merged_default_settings.instances), local.merged_default_settings.instances)
      "enable_cloudwatch_alarm"      = coalesce(lookup(v, "enable_cloudwatch_alarm", null), local.merged_default_settings.enable_cloudwatch_alarm)
      "alarms" = {
        for k1, v1 in coalesce(lookup(v, "alarms", null), {}) : k1 => {
          "identifier"              = "${module.context.id}-${k}-${k1}"
          "metric_name"             = v1.metric_name
          "threshold"               = v1.threshold
          "period"                  = v1.period
          "evaluation_periods"      = v1.evaluation_periods
          "dimensions"              = coalesce(lookup(v1, "dimensions", null), local.merged_default_settings.alarms.dimensions)
          "comparison_operator"     = coalesce(lookup(v1, "comparison_operator", null), local.merged_default_settings.alarms.comparison_operator)
          "statistic"               = coalesce(lookup(v1, "statistic", null), local.merged_default_settings.alarms.statistic)
          "namespace"               = coalesce(lookup(v1, "namespace", null), local.merged_default_settings.alarms.namespace)
          "cloudwatch_alarm_action" = try(coalesce(lookup(v1, "cloudwatch_alarm_action", null), local.merged_default_settings.alarms.cloudwatch_alarm_action), local.merged_default_settings.alarms.cloudwatch_alarm_action)
        }
      }
    } if coalesce(lookup(v, "create", true), true)
  }
}

data "aws_rds_engine_version" "aurora" {
  for_each = local.aurora_map
  engine   = "aurora-postgresql"
  version  = each.value.version
}

resource "random_password" "password" {
  for_each = local.aurora_map
  length   = 16
  special  = false
}

resource "aws_secretsmanager_secret" "secret" {
  for_each = { for k, v in local.aurora_map : k => v if v.create }
  name     = "${var.org_name}-${var.stage_name}/rds/${each.value.identifier}"
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each = {
    for k, v in local.aurora_map : k => {
      secret_id = aws_secretsmanager_secret.secret[k].id
      secret_string = jsonencode({
        username = v.master_username
        password = random_password.password[k].result
        endpoint = module.aurora_postgresql_v2[k].cluster_endpoint
      })
    } if v.create
  }
  secret_id     = each.value.secret_id
  secret_string = each.value.secret_string
}

module "aurora_postgresql_v2" {
  source         = "terraform-aws-modules/rds-aurora/aws"
  version        = "~> 8.3.1"
  for_each       = local.aurora_map
  name           = each.value.identifier
  engine         = data.aws_rds_engine_version.aurora[each.key].engine
  engine_mode    = "provisioned"
  engine_version = data.aws_rds_engine_version.aurora[each.key].version
  instance_class = "db.serverless"
  serverlessv2_scaling_configuration = {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
  }
  database_name               = each.value.database_name
  master_username             = each.value.master_username
  manage_master_user_password = false
  master_password             = random_password.password[each.key].result
  vpc_id                      = var.vpc_id
  create_db_subnet_group      = true
  subnets                     = var.subnet_ids
  security_group_rules = merge({
    vpc_ingress = {
      cidr_blocks = var.ingress_cidr_blocks
    }
    vpc_egress = {
      type        = "egress"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  }, var.security_group_rules)
  deletion_protection          = each.value.deletion_protection
  storage_encrypted            = true
  monitoring_interval          = each.value.monitoring_interval
  performance_insights_enabled = each.value.performance_insights_enabled
  backup_retention_period      = each.value.backup_retention_period
  apply_immediately            = true
  skip_final_snapshot          = each.value.skip_final_snapshot
  instances                    = { for i in range(1, each.value.instances_count + 1) : i => try(each.value.instances[i], {}) }
  copy_tags_to_snapshot        = true
  tags                         = local.tags
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "invoke_lambda_policy" {
  for_each = { for k, v in local.aurora_map : k => v if length(v.lambda_functions) > 0 }
  name     = "${each.value.identifier}-invoke-lambda"
  path     = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = [for item in each.value.lambda_functions : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${item}*"]
      },
    ]
  })
}

resource "aws_iam_role" "rds_invoke_lambda_role" {
  for_each = { for k, v in local.aurora_map : k => v if length(v.lambda_functions) > 0 }
  name     = "${each.value.identifier}-invoke-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_lambda_role_attach" {
  for_each   = { for k, v in local.aurora_map : k => v if length(v.lambda_functions) > 0 }
  role       = aws_iam_role.rds_invoke_lambda_role[each.key].name
  policy_arn = aws_iam_policy.invoke_lambda_policy[each.key].arn
}

resource "aws_rds_cluster_role_association" "rds_lambda_role_attach" {
  for_each              = { for k, v in local.aurora_map : k => v if length(v.lambda_functions) > 0 }
  db_cluster_identifier = module.aurora_postgresql_v2[each.key].cluster_id
  feature_name          = "Lambda"
  role_arn              = aws_iam_role.rds_invoke_lambda_role[each.key].arn
}

locals {
  alarms_map = merge([
    for k, v in local.aurora_map : {
      for k1, v1 in v.alarms : "${k}|${k1}" => v1
    } if v.create && v.enable_cloudwatch_alarm && length(v.alarms) > 0
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each            = local.alarms_map
  alarm_name          = local.alarms_map[each.key].identifier
  alarm_description   = "This metric monitors RDS ${local.aurora_map[split("|", each.key)[0]].identifier} ${local.alarms_map[each.key].metric_name}"
  metric_name         = local.alarms_map[each.key].metric_name
  comparison_operator = local.alarms_map[each.key].comparison_operator
  statistic           = local.alarms_map[each.key].statistic
  threshold           = local.alarms_map[each.key].threshold
  period              = local.alarms_map[each.key].period
  evaluation_periods  = local.alarms_map[each.key].evaluation_periods
  namespace           = local.alarms_map[each.key].namespace
  dimensions = merge({
    DBClusterIdentifier = module.aurora_postgresql_v2[split("|", each.key)[0]].cluster_id
  }, lookup(local.alarms_map[each.key], "dimensions", {}))
  alarm_actions = compact([
    var.sns_topic_arn,
    lookup(local.aurora_map[split("|", each.key)[0]], "cloudwatch_alarm_action", "")
  ])
}