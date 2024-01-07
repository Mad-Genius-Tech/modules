locals {
  default_settings = {
    instance_class                        = "db.t4g.micro"
    allocated_storage                     = 20
    max_allocated_storage                 = 0
    db_name                               = "testdb"
    username                              = "postgres"
    port                                  = 5432
    maintenance_window                    = "Mon:00:00-Mon:03:00"
    backup_window                         = "04:00-07:00"
    multi_az                              = false
    backup_retention_period               = 1
    skip_final_snapshot                   = true
    deletion_protection                   = false
    performance_insights_enabled          = false
    performance_insights_retention_period = null
    create_cloudwatch_log_group           = false
    enabled_cloudwatch_logs_exports       = []
    create_monitoring_role                = false
    monitoring_interval                   = 0
    monitoring_role_name                  = module.context.id
    monitoring_role_use_name_prefix       = true
    create_db_subnet_group                = true
    subnet_ids                            = var.subnet_ids
    parameters                            = []
    options                               = []
    lambda_functions                      = []
    apply_immediately                     = true
    secret_rotation_enabled               = false
    enable_cloudwatch_alarm               = false
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
        multi_az                              = true
        backup_retention_period               = 35
        skip_final_snapshot                   = false
        deletion_protection                   = true
        performance_insights_enabled          = true
        performance_insights_retention_period = 7
        create_cloudwatch_log_group           = true
        enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
        create_monitoring_role                = true
        monitoring_interval                   = 60
        enable_cloudwatch_alarm               = true
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  rds_map = {
    for k, v in var.rds : k => {
      "create"                                = coalesce(lookup(v, "create", null), true)
      "identifier"                            = "${module.context.id}-${k}"
      "engine"                                = "postgres"
      "engine_version"                        = v.engine_version
      "major_engine_version"                  = split(".", v.engine_version)[0]
      "family"                                = "postgres${split(".", v.engine_version)[0]}"
      "instance_class"                        = coalesce(lookup(v, "instance_class", null), local.merged_default_settings.instance_class)
      "allocated_storage"                     = coalesce(lookup(v, "allocated_storage", null), local.merged_default_settings.allocated_storage)
      "max_allocated_storage"                 = coalesce(lookup(v, "max_allocated_storage", null), coalesce(v.allocated_storage, local.merged_default_settings.max_allocated_storage))
      "db_name"                               = coalesce(lookup(v, "db_name", null), local.merged_default_settings.db_name)
      "username"                              = coalesce(lookup(v, "username", null), local.merged_default_settings.username)
      "port"                                  = coalesce(lookup(v, "port", null), local.merged_default_settings.port)
      "parameters"                            = coalesce(lookup(v, "parameters", null), local.merged_default_settings.parameters)
      "options"                               = coalesce(lookup(v, "options", null), local.merged_default_settings.options)
      "maintenance_window"                    = local.merged_default_settings.maintenance_window
      "backup_window"                         = local.merged_default_settings.backup_window
      "create_db_subnet_group"                = local.merged_default_settings.create_db_subnet_group
      "subnet_ids"                            = local.merged_default_settings.subnet_ids
      "multi_az"                              = local.merged_default_settings.multi_az
      "backup_retention_period"               = local.merged_default_settings.backup_retention_period
      "skip_final_snapshot"                   = local.merged_default_settings.skip_final_snapshot
      "deletion_protection"                   = local.merged_default_settings.deletion_protection
      "performance_insights_enabled"          = local.merged_default_settings.performance_insights_enabled
      "performance_insights_retention_period" = local.merged_default_settings.performance_insights_retention_period
      "create_cloudwatch_log_group"           = local.merged_default_settings.create_cloudwatch_log_group
      "enabled_cloudwatch_logs_exports"       = local.merged_default_settings.enabled_cloudwatch_logs_exports
      "create_monitoring_role"                = local.merged_default_settings.create_monitoring_role
      "monitoring_interval"                   = local.merged_default_settings.monitoring_interval
      "monitoring_role_name"                  = local.merged_default_settings.monitoring_role_name
      "monitoring_role_use_name_prefix"       = local.merged_default_settings.monitoring_role_use_name_prefix
      "lambda_functions"                      = coalesce(lookup(v, "lambda_functions", null), local.merged_default_settings.lambda_functions)
      "apply_immediately"                     = coalesce(lookup(v, "apply_immediately", null), local.merged_default_settings.apply_immediately)
      "secret_rotation_enabled"               = coalesce(lookup(v, "secret_rotation_enabled", null), local.merged_default_settings.secret_rotation_enabled)
      "enable_cloudwatch_alarm"               = coalesce(lookup(v, "enable_cloudwatch_alarm", null), local.merged_default_settings.enable_cloudwatch_alarm)
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
    } if coalesce(lookup(v, "create", null), true)
  }
}

module "rds" {
  for_each                              = local.rds_map
  source                                = "terraform-aws-modules/rds/aws"
  version                               = "~> 6.1.1"
  identifier                            = each.value.identifier
  engine                                = each.value.engine
  engine_version                        = each.value.engine_version
  family                                = each.value.family
  major_engine_version                  = each.value.major_engine_version
  instance_class                        = each.value.instance_class
  allocated_storage                     = each.value.allocated_storage
  max_allocated_storage                 = each.value.max_allocated_storage
  db_name                               = each.value.db_name
  username                              = each.value.username
  port                                  = each.value.port
  multi_az                              = each.value.multi_az
  create_db_subnet_group                = each.value.create_db_subnet_group
  subnet_ids                            = each.value.subnet_ids
  vpc_security_group_ids                = [module.rds_sg[each.key].security_group_id]
  maintenance_window                    = each.value.maintenance_window
  backup_window                         = each.value.backup_window
  backup_retention_period               = each.value.backup_retention_period
  skip_final_snapshot                   = each.value.skip_final_snapshot
  deletion_protection                   = each.value.deletion_protection
  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_retention_period = each.value.performance_insights_retention_period
  create_cloudwatch_log_group           = each.value.create_cloudwatch_log_group
  enabled_cloudwatch_logs_exports       = each.value.enabled_cloudwatch_logs_exports
  create_monitoring_role                = each.value.create_monitoring_role
  monitoring_interval                   = each.value.monitoring_interval
  monitoring_role_name                  = each.value.monitoring_role_name
  monitoring_role_use_name_prefix       = each.value.monitoring_role_use_name_prefix
  parameters                            = each.value.parameters
  options                               = each.value.options
  apply_immediately                     = each.value.apply_immediately
  tags                                  = local.tags
}

module "rds_sg" {
  for_each           = local.rds_map
  source             = "terraform-aws-modules/security-group/aws"
  version            = "~> 5.1.0"
  name               = "${each.value.identifier}-sg"
  description        = "RDS ${each.value.identifier} Security group"
  vpc_id             = var.vpc_id
  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  computed_ingress_with_source_security_group_id = length(var.ingress_security_group_id) > 0 ? [
    {
      rule                     = "postgres-tcp"
      source_security_group_id = var.ingress_security_group_id
    }
  ] : []
  number_of_computed_ingress_with_source_security_group_id = length(var.ingress_security_group_id) > 0 ? 1 : 0

  computed_ingress_with_cidr_blocks = length(var.ingress_cidr_blocks) > 0 ? [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = join(",", var.ingress_cidr_blocks)
    }
  ] : []
  number_of_computed_ingress_with_cidr_blocks = length(var.ingress_cidr_blocks) > 0 ? 1 : 0
}


data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "invoke_lambda_policy" {
  for_each = { for k, v in local.rds_map : k => v if length(v.lambda_functions) > 0 }
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
  for_each = { for k, v in local.rds_map : k => v if length(v.lambda_functions) > 0 }
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
  for_each   = { for k, v in local.rds_map : k => v if length(v.lambda_functions) > 0 }
  role       = aws_iam_role.rds_invoke_lambda_role[each.key].name
  policy_arn = aws_iam_policy.invoke_lambda_policy[each.key].arn
}

resource "aws_db_instance_role_association" "rds_lambda_role_attach" {
  for_each               = { for k, v in local.rds_map : k => v if length(v.lambda_functions) > 0 }
  db_instance_identifier = module.rds[each.key].db_instance_identifier
  feature_name           = "Lambda"
  role_arn               = aws_iam_role.rds_invoke_lambda_role[each.key].arn
}

resource "null_resource" "disable_secret_rotation" {
  for_each = { for k, v in local.rds_map : k => v if !v.secret_rotation_enabled }
  provisioner "local-exec" {
    command = "if [[ -z $AWS_PROFILE ]]; then AWS_PROFILE=$AWS_PROFILE aws secretsmanager cancel-rotate-secret --region ${data.aws_region.current.name} --secret-id '${module.rds[each.key].db_instance_master_user_secret_arn}'; else aws secretsmanager cancel-rotate-secret --region ${data.aws_region.current.name} --secret-id '${module.rds[each.key].db_instance_master_user_secret_arn}'; fi"
  }
}

data "aws_secretsmanager_secret_version" "secret" {
  for_each  = { for k, v in local.rds_map : k => v if var.enable_secret_manager && v.create }
  secret_id = module.rds[each.key].db_instance_master_user_secret_arn
}

resource "aws_secretsmanager_secret" "secret" {
  for_each = { for k, v in local.rds_map : k => v if var.enable_secret_manager && v.create }
  name     = "${var.org_name}-${var.stage_name}/rds/${each.value.identifier}"
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each = {
    for k, v in local.rds_map : k => {
      secret_id = aws_secretsmanager_secret.secret[k].id
      secret_string = jsonencode({
        "username" = v.username
        "password" = jsondecode(data.aws_secretsmanager_secret_version.secret[k].secret_string)["password"]
        "endpoint" = module.rds[k].db_instance_address
      })
    } if var.enable_secret_manager && v.create
  }
  secret_id     = each.value.secret_id
  secret_string = each.value.secret_string
}

locals {
  alarms_map = merge([
    for k, v in local.rds_map : {
      for k1, v1 in v.alarms : "${k}|${k1}" => v1
    } if v.create && v.enable_cloudwatch_alarm && length(v.alarms) > 0
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each            = local.alarms_map
  alarm_name          = local.alarms_map[each.key].identifier
  alarm_description   = "This metric monitors RDS ${local.rds_map[split("|", each.key)[0]].identifier} ${local.alarms_map[each.key].metric_name}"
  metric_name         = local.alarms_map[each.key].metric_name
  comparison_operator = local.alarms_map[each.key].comparison_operator
  statistic           = local.alarms_map[each.key].statistic
  threshold           = local.alarms_map[each.key].threshold
  period              = local.alarms_map[each.key].period
  evaluation_periods  = local.alarms_map[each.key].evaluation_periods
  namespace           = local.alarms_map[each.key].namespace
  dimensions = merge({
    DBInstanceIdentifier = module.rds[split("|", each.key)[0]].db_instance_identifier
  }, lookup(local.alarms_map[each.key], "dimensions", {}))
  alarm_actions = compact([
    var.sns_topic_arn,
    lookup(local.rds_map[split("|", each.key)[0]], "cloudwatch_alarm_action", "")
  ])
  ok_actions = compact([
    var.sns_topic_arn,
    lookup(local.rds_map[split("|", each.key)[0]], "cloudwatch_alarm_action", "")
  ])
  tags = local.tags
}