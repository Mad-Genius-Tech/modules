data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  default_settings = {
    type                        = "STANDARD"
    publish                     = true
    create_iam_role             = true
    create_log_group            = true
    log_group_retention_in_days = 3
    logging_configuration = {
      include_execution_data = false
      level                  = "ERROR"
    }
    service_integrations = {}
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        log_group_retention_in_days = 7
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  sfn_map = {
    for k, v in var.step_function : k => {
      "identifier"                  = "${module.context.id}-${k}"
      "create"                      = coalesce(lookup(v, "create", null), true)
      "type"                        = try(coalesce(lookup(v, "type", null), local.merged_default_settings.type), local.merged_default_settings.type)
      "definition"                  = v.definition
      "publish"                     = try(coalesce(lookup(v, "publish", null), local.merged_default_settings.publish), local.merged_default_settings.publish)
      "create_iam_role"             = try(coalesce(lookup(v, "create_iam_role", null), local.merged_default_settings.create_iam_role), local.merged_default_settings.create_iam_role)
      "create_log_group"            = try(coalesce(lookup(v, "create_log_group", null), local.merged_default_settings.create_log_group), local.merged_default_settings.create_log_group)
      "log_group_retention_in_days" = try(coalesce(lookup(v, "log_group_retention_in_days", null), local.merged_default_settings.log_group_retention_in_days), local.merged_default_settings.log_group_retention_in_days)
      "logging_configuration"       = try(coalesce(lookup(v, "logging_configuration", null), local.merged_default_settings.logging_configuration), local.merged_default_settings.logging_configuration)
      "service_integrations"        = try(coalesce(lookup(v, "service_integrations", null), local.merged_default_settings.service_integrations), local.merged_default_settings.service_integrations)



    } if coalesce(lookup(v, "create", null), true)
  }
}


module "step_function" {
  source                            = "terraform-aws-modules/step-functions/aws"
  version                           = "~> 4.2.0"
  for_each                          = local.sfn_map
  create                            = each.value.create
  name                              = each.value.identifier
  type                              = each.value.type
  definition                        = each.value.definition
  publish                           = each.value.publish
  use_existing_cloudwatch_log_group = each.value.create_log_group ? true : false
  cloudwatch_log_group_name         = each.value.create_log_group ? aws_cloudwatch_log_group.log_group[each.key].name : null
  logging_configuration             = each.value.logging_configuration
  create_role                       = each.value.create_iam_role ? false : true
  use_existing_role                 = each.value.create_iam_role ? true : false
  role_arn                          = each.value.create_iam_role ? aws_iam_role.step_function[each.key].arn : ""
  tags                              = local.tags
  depends_on                        = [aws_cloudwatch_log_group.log_group]
}

resource "aws_cloudwatch_log_group" "log_group" {
  for_each          = { for k, v in local.sfn_map : k => v if v.create_log_group }
  name              = each.value.identifier
  retention_in_days = each.value.log_group_retention_in_days
  tags              = local.tags
}

resource "aws_iam_role" "step_function" {
  for_each = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  name     = each.value.identifier
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
  tags = local.tags
}

data "aws_iam_policy_document" "lambda_policy" {
  for_each = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync"
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.org_name}-${var.stage_name}-*"
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  for_each = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  name     = "${each.value.identifier}-lambda"
  policy   = data.aws_iam_policy_document.lambda_policy[each.key].json
  tags     = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  for_each   = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  role       = aws_iam_role.step_function[each.key].name
  policy_arn = aws_iam_policy.lambda_policy[each.key].arn
}

data "aws_iam_policy_document" "log_policy" {
  for_each = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.log_group[each.key].arn}:*"
    ]
  }
}

resource "aws_iam_policy" "log_policy" {
  for_each = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  name     = "${each.value.identifier}-logs"
  policy   = data.aws_iam_policy_document.log_policy[each.key].json
  tags     = local.tags
}

resource "aws_iam_role_policy_attachment" "log_policy" {
  for_each   = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  role       = aws_iam_role.step_function[each.key].name
  policy_arn = aws_iam_policy.log_policy[each.key].arn
}


data "aws_iam_policy_document" "sns_policy" {
  for_each = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  statement {
    actions = [
      "sns:Publish",
      "sns:SetSMSAttributes",
      "sns:GetSMSAttributes",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "sns_policy" {
  for_each = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  name     = "${each.value.identifier}-sns"
  policy   = data.aws_iam_policy_document.sns_policy[each.key].json
  tags     = local.tags
}

resource "aws_iam_role_policy_attachment" "sns_policy" {
  for_each   = { for k, v in local.sfn_map : k => v if v.create_iam_role }
  role       = aws_iam_role.step_function[each.key].name
  policy_arn = aws_iam_policy.sns_policy[each.key].arn
}