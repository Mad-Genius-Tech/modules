
locals {
  default_settings = {
    "domain_names"                = {}
    "endpoint_type"               = ["REGIONAL"]
    "enable_stage"                = true
    "connection_type"             = "INTERNET"
    "enable_log"                  = false
    "create_log_group"            = false
    "log_group_retention_in_days" = 1
    "logging_level"               = "OFF" # Supported only for WebSocket APIs
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  apigateway_map = {
    for k, v in var.apigateway : k => {
      "create"                      = coalesce(lookup(v, "create", null), true)
      "identifier"                  = "${module.context.id}-${k}"
      "enable_stage"                = coalesce(lookup(v, "enable_stage", null), local.merged_default_settings.enable_stage)
      "lambda_function"             = v.lambda_function
      "stage_name"                  = coalesce(lookup(v, "stage_name", null), var.stage_name)
      "connection_type"             = coalesce(lookup(v, "connection_type", null), local.merged_default_settings.connection_type)
      enable_log                    = coalesce(lookup(v, "enable_log", null), local.merged_default_settings.enable_log)
      "logging_level"               = coalesce(lookup(v, "logging_level", null), local.merged_default_settings.logging_level)
      "create_log_group"            = coalesce(lookup(v, "create_log_group", null), local.merged_default_settings.create_log_group)
      "log_group_retention_in_days" = coalesce(lookup(v, "log_group_retention_in_days", null), local.merged_default_settings.log_group_retention_in_days)
    } if coalesce(lookup(v, "create", true), true)
  }
}

data "aws_region" "current" {}

resource "aws_apigatewayv2_api" "apigateway" {
  for_each      = local.apigateway_map
  name          = each.value.identifier
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "log_group" {
  for_each          = { for k, v in local.apigateway_map : k => v if v.enable_log && v.create_log_group }
  name              = each.value.identifier
  retention_in_days = each.value.log_group_retention_in_days
  tags              = local.tags
}

resource "aws_apigatewayv2_stage" "stage" {
  for_each    = local.apigateway_map
  api_id      = aws_apigatewayv2_api.apigateway[each.key].id
  name        = each.value.stage_name
  auto_deploy = true

  default_route_settings {
    # Supported only for WebSocket APIs
    # logging_level            = each.value.logging_level
    detailed_metrics_enabled = false
    data_trace_enabled       = false
    throttling_burst_limit   = 5000
    throttling_rate_limit    = 10000
  }

  dynamic "access_log_settings" {
    for_each = { for k, v in local.apigateway_map : k => v if v.enable_log && v.create_log_group }
    content {
      destination_arn = aws_cloudwatch_log_group.log_group[each.key].arn
      format = jsonencode({
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        sourceIp                = "$context.identity.sourceIp"
        protocol                = "$context.protocol"
        httpMethod              = "$context.httpMethod"
        resourcePath            = "$context.resourcePath"
        routeKey                = "$context.routeKey"
        status                  = "$context.status"
        responseLength          = "$context.responseLength"
        integrationErrorMessage = "$context.integrationErrorMessage"
        }
      )
    }
  }
}

data "aws_lambda_function" "lambda_function" {
  for_each      = { for k, v in local.apigateway_map : k => v if v.create }
  function_name = each.value.lambda_function
}

resource "aws_apigatewayv2_integration" "integration" {
  for_each               = local.apigateway_map
  api_id                 = aws_apigatewayv2_api.apigateway[each.key].id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  connection_type        = each.value.connection_type
  integration_uri        = data.aws_lambda_function.lambda_function[each.key].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  for_each  = local.apigateway_map
  api_id    = aws_apigatewayv2_api.apigateway[each.key].id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.integration[each.key].id}"
}

resource "aws_lambda_permission" "api_gateway" {
  for_each      = local.apigateway_map
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigateway[each.key].execution_arn}/*/*"
}
