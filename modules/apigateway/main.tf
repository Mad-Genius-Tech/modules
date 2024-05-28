

locals {
  default_settings = {
    "domain_names"                = {}
    "endpoint_type"               = ["REGIONAL"]
    "xray_tracing_enabled"        = false
    "create_log_group"            = true
    "apigw_exec_log_level"        = "OFF"
    "data_trace_enabled"          = false
    "log_group_retention_in_days" = 1
    "timeout_milliseconds"        = 29000
    "enable_cors"                 = false
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        "endpoint_type"               = ["EDGE"]
        "log_group_retention_in_days" = 3
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  apigateway_map = {
    for k, v in var.apigateway : k => {
      "create"                      = coalesce(lookup(v, "create", null), true)
      "identifier"                  = "${module.context.id}-${k}"
      "endpoint_type"               = coalesce(lookup(v, "endpoint_type", null), local.merged_default_settings.endpoint_type)
      "domain_names"                = try(coalesce(lookup(v, "domain_names", null), local.merged_default_settings.domain_names), local.merged_default_settings.domain_names)
      "xray_tracing_enabled"        = coalesce(lookup(v, "xray_tracing_enabled", null), local.merged_default_settings.xray_tracing_enabled)
      "lambda_function"             = v.lambda_function
      "stage_name"                  = coalesce(lookup(v, "stage_name", null), var.stage_name)
      "create_log_group"            = coalesce(lookup(v, "create_log_group", null), local.merged_default_settings.create_log_group)
      "apigw_exec_log_level"        = coalesce(lookup(v, "apigw_exec_log_level", null), local.merged_default_settings.apigw_exec_log_level)
      "data_trace_enabled"          = coalesce(lookup(v, "data_trace_enabled", null), local.merged_default_settings.data_trace_enabled)
      "log_group_retention_in_days" = coalesce(lookup(v, "log_group_retention_in_days", null), local.merged_default_settings.log_group_retention_in_days)
      "timeout_milliseconds"        = coalesce(lookup(v, "timeout_milliseconds", null), local.merged_default_settings.timeout_milliseconds)
      "enable_cors"                 = coalesce(lookup(v, "enable_cors", null), local.merged_default_settings.enable_cors)
    } if coalesce(lookup(v, "create", true), true)
  }
}

data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "rest_api" {
  for_each           = local.apigateway_map
  name               = each.value.identifier
  binary_media_types = ["*/*"]
  endpoint_configuration {
    types = each.value.endpoint_type
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = local.tags
}

resource "aws_api_gateway_method" "root_path" {
  for_each      = local.apigateway_map
  rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
  resource_id   = aws_api_gateway_rest_api.rest_api[each.key].root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

data "aws_lambda_function" "lambda_function" {
  for_each      = { for k, v in local.apigateway_map : k => v if v.create }
  function_name = each.value.lambda_function
}

resource "aws_api_gateway_integration" "root_path_integration" {
  for_each                = local.apigateway_map
  rest_api_id             = aws_api_gateway_rest_api.rest_api[each.key].id
  resource_id             = aws_api_gateway_rest_api.rest_api[each.key].root_resource_id
  http_method             = aws_api_gateway_method.root_path[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  timeout_milliseconds    = each.value.timeout_milliseconds
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${data.aws_lambda_function.lambda_function[each.key].arn}:$${stageVariables.lambdaAliasName}/invocations"
}

resource "aws_api_gateway_resource" "any_path_slashed" {
  for_each    = local.apigateway_map
  rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
  parent_id   = aws_api_gateway_rest_api.rest_api[each.key].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "any_path_slashed" {
  for_each      = local.apigateway_map
  rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
  resource_id   = aws_api_gateway_resource.any_path_slashed[each.key].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "any_path_slashed_integration" {
  for_each                = local.apigateway_map
  rest_api_id             = aws_api_gateway_rest_api.rest_api[each.key].id
  resource_id             = aws_api_gateway_resource.any_path_slashed[each.key].id
  http_method             = aws_api_gateway_method.any_path_slashed[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  timeout_milliseconds    = each.value.timeout_milliseconds
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${data.aws_lambda_function.lambda_function[each.key].arn}:$${stageVariables.lambdaAliasName}/invocations"
}

resource "aws_api_gateway_deployment" "deployment" {
  for_each    = local.apigateway_map
  rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id

  depends_on = [
    aws_api_gateway_integration.root_path_integration,
    aws_api_gateway_integration.any_path_slashed_integration,
    # aws_api_gateway_integration.root_path_options_integration,
    # aws_api_gateway_integration.any_path_slashed_options_integration,
    aws_api_gateway_resource.any_path_slashed,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.rest_api[each.key].id,
      aws_api_gateway_rest_api.rest_api[each.key].body,
      aws_api_gateway_method.any_path_slashed[each.key].id,
      aws_api_gateway_integration.any_path_slashed_integration[each.key].id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  for_each          = { for k, v in local.apigateway_map : k => v if v.create_log_group == true }
  name              = each.value.identifier
  retention_in_days = each.value.log_group_retention_in_days
  tags              = local.tags
}

resource "aws_api_gateway_stage" "stage" {
  for_each             = local.apigateway_map
  rest_api_id          = aws_api_gateway_rest_api.rest_api[each.key].id
  deployment_id        = aws_api_gateway_deployment.deployment[each.key].id
  stage_name           = each.value.stage_name
  xray_tracing_enabled = each.value.xray_tracing_enabled


  variables = {
    lambdaAliasName = each.value.stage_name
  }

  dynamic "access_log_settings" {
    for_each = each.value.apigw_exec_log_level == "OFF" ? [1] : []

    content {
      destination_arn = aws_cloudwatch_log_group.log_group[each.key].arn
      format          = replace(var.access_log_format, "\n", "")
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.log_group,
    aws_api_gateway_account.apigateway_cloudwatch_logs
  ]
  tags = local.tags
}

resource "aws_api_gateway_method_settings" "rest_api" {
  for_each    = { for k, v in local.apigateway_map : k => v if v.create && v.apigw_exec_log_level != "OFF" }
  rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
  stage_name  = aws_api_gateway_stage.stage[each.key].stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = -1
    throttling_rate_limit  = -1
    metrics_enabled        = false
    data_trace_enabled     = each.value.data_trace_enabled
    logging_level          = each.value.apigw_exec_log_level #OFF, ERROR, INFO
  }

  depends_on = [
    aws_cloudwatch_log_group.apigateway_exec_log_group,
  ]
}

resource "aws_cloudwatch_log_group" "apigateway_exec_log_group" {
  for_each          = { for k, v in local.apigateway_map : k => v if v.create }
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.rest_api[each.key].id}/${aws_api_gateway_stage.stage[each.key].stage_name}"
  retention_in_days = each.value.log_group_retention_in_days
  tags              = local.tags
}

resource "aws_api_gateway_stage" "test" {
  for_each      = local.apigateway_map
  rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
  deployment_id = aws_api_gateway_deployment.deployment[each.key].id
  stage_name    = "test"

  variables = {
    lambdaAliasName = "test"
  }

  tags = local.tags
}

resource "aws_lambda_permission" "api_gateway" {
  for_each      = local.apigateway_map
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function
  principal     = "apigateway.amazonaws.com"
  qualifier     = each.value.stage_name
  source_arn    = "${aws_api_gateway_rest_api.rest_api[each.key].execution_arn}/${each.value.stage_name}/*/*"
}

resource "aws_lambda_permission" "api_gateway_test" {
  for_each      = local.apigateway_map
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function
  principal     = "apigateway.amazonaws.com"
  qualifier     = "test"
  source_arn    = "${aws_api_gateway_rest_api.rest_api[each.key].execution_arn}/test/*/*"
}

resource "aws_lambda_permission" "api_gateway_all" {
  for_each      = local.apigateway_map
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api[each.key].execution_arn}/*"
}

resource "aws_api_gateway_account" "apigateway_cloudwatch_logs" {
  count               = var.stage_name == "prod" ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_logs[0].arn
}

resource "aws_iam_role" "apigateway_cloudwatch_logs" {
  count = var.stage_name == "prod" ? 1 : 0
  name  = "${module.context.id}-logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = local.tags
}

resource "aws_iam_role_policy" "apigateway_cloudwatch_logs" {
  count  = var.stage_name == "prod" ? 1 : 0
  name   = "${module.context.id}-logs"
  role   = aws_iam_role.apigateway_cloudwatch_logs[0].id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


###############
# Enable CORS #
# For a Lambda proxy integration or HTTP proxy integration, 
# your backend is responsible for returning the Access-Control-Allow-Origin, Access-Control-Allow-Methods, and Access-Control-Allow-Headers headers, 
# because a proxy integration doesn't return an integration response.
# https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html
###############
# resource "aws_api_gateway_method" "root_path_options_method" {
#   for_each      = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id   = aws_api_gateway_rest_api.rest_api[each.key].root_resource_id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "root_path_options_integration" {
#   for_each    = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id = aws_api_gateway_method.root_path_options_method[each.key].resource_id
#   http_method = aws_api_gateway_method.root_path_options_method[each.key].http_method
#   type        = "MOCK"

#   request_templates = {
#     "application/json" = jsonencode({
#       statusCode = 200
#     })
#   }
# }

# resource "aws_api_gateway_method_response" "root_path_options_200" {
#   for_each    = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id = aws_api_gateway_method.root_path_options_method[each.key].resource_id
#   http_method = aws_api_gateway_method.root_path_options_method[each.key].http_method
#   status_code = "200"

#   response_models = {
#     "application/json" = "Empty"
#   }

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#     "method.response.header.Access-Control-Allow-Origin"  = true
#   }
# }

# resource "aws_api_gateway_integration_response" "root_path_options_integration_response" {
#   for_each    = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id = aws_api_gateway_method.root_path_options_method[each.key].resource_id
#   http_method = aws_api_gateway_method.root_path_options_method[each.key].http_method
#   status_code = aws_api_gateway_method_response.root_path_options_200[each.key].status_code

#   response_templates = {
#     "application/json" = jsonencode({
#       statusCode = 200
#       message    = "OK! From root path"
#     })
#   }

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = "'*'"
#     # "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'"
#     "method.response.header.Access-Control-Allow-Methods" = "'*'"
#     # "method.response.header.Access-Control-Allow-Methods" = "'GET,HEAD,OPTIONS,PATCH,POST,PUT,DELETE'"
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
#   }

#   depends_on = [
#     aws_api_gateway_integration.root_path_options_integration,
#   ]
# }

# resource "aws_api_gateway_method" "any_path_slashed_options_method" {
#   for_each      = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id   = aws_api_gateway_resource.any_path_slashed[each.key].id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "any_path_slashed_options_integration" {
#   for_each    = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id = aws_api_gateway_resource.any_path_slashed[each.key].id
#   http_method = aws_api_gateway_method.any_path_slashed_options_method[each.key].http_method
#   type        = "MOCK"

#   request_templates = {
#     "application/json" = jsonencode({
#       statusCode = 200
#     })
#   }
# }

# resource "aws_api_gateway_method_response" "any_path_slashed_options_200" {
#   for_each    = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id = aws_api_gateway_resource.any_path_slashed[each.key].id
#   http_method = aws_api_gateway_method.any_path_slashed_options_method[each.key].http_method
#   status_code = "200"

#   response_models = {
#     "application/json" = "Empty"
#   }

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#     "method.response.header.Access-Control-Allow-Origin"  = true
#   }
# }

# resource "aws_api_gateway_integration_response" "any_path_slashed_options_integration_response" {
#   for_each    = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
#   resource_id = aws_api_gateway_resource.any_path_slashed[each.key].id
#   http_method = aws_api_gateway_method.any_path_slashed_options_method[each.key].http_method
#   status_code = aws_api_gateway_method_response.any_path_slashed_options_200[each.key].status_code

#   response_templates = {
#     "application/json" = jsonencode({
#       statusCode = 200
#       message    = "OK! Everything in order"
#     })
#   }

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = "'*'"
#     # "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'"
#     "method.response.header.Access-Control-Allow-Methods" = "'*'"
#     # "method.response.header.Access-Control-Allow-Methods" = "'GET,HEAD,OPTIONS,PATCH,POST,PUT,DELETE'"
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
#   }

#   depends_on = [
#     aws_api_gateway_integration.any_path_slashed_options_integration,
#   ]
# }

# resource "aws_api_gateway_gateway_response" "response_4xx" {
#   for_each      = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
#   response_type = "DEFAULT_4XX"

#   response_templates = {
#     "application/json" = "{'message':$context.error.messageString}"
#   }

#   response_parameters = {
#     "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
#   }
# }

# resource "aws_api_gateway_gateway_response" "response_5xx" {
#   for_each      = { for k, v in local.apigateway_map : k => v if v.create && v.enable_cors }
#   rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
#   response_type = "DEFAULT_5XX"

#   response_templates = {
#     "application/json" = "{'message':$context.error.messageString}"
#   }

#   response_parameters = {
#     "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
#   }
# }

#####################
# SSL custom domain #
#####################

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

locals {
  domain_names = merge([
    for k, v in local.apigateway_map : {
      for k1, v1 in v.domain_names : "${k}|${k1}" => {
        "domain_name"         = v1.domain_name
        "use_wildcard_domain" = coalesce(lookup(v1, "use_wildcard_domain", true), true)
        "use_acm"             = coalesce(lookup(v1, "use_acm", true), true)
        "endpoint_type"       = v.endpoint_type[0]
      }
    } if v.create && length(v.domain_names) > 0
  ]...)
}

data "aws_acm_certificate" "wildcard" {
  for_each = { for k, v in local.domain_names : k => v if v.use_wildcard_domain && v.endpoint_type == "EDGE" && v.use_acm }
  domain   = length(split(".", each.value.domain_name)) > 2 ? join(".", slice(split(".", each.value.domain_name), 1, length(split(".", each.value.domain_name)))) : each.value.domain_name
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

data "aws_acm_certificate" "non_wildcard" {
  for_each = { for k, v in local.domain_names : k => v if !v.use_wildcard_domain && v.endpoint_type == "EDGE" && v.use_acm }
  domain   = each.value.domain_name
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

data "aws_acm_certificate" "regional_wildcard" {
  for_each = { for k, v in local.domain_names : k => v if v.use_wildcard_domain && v.endpoint_type == "REGIONAL" && v.use_acm }
  domain   = length(split(".", each.value.domain_name)) > 2 ? join(".", slice(split(".", each.value.domain_name), 1, length(split(".", each.value.domain_name)))) : each.value.domain_name
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "regional_non_wildcard" {
  for_each = { for k, v in local.domain_names : k => v if !v.use_wildcard_domain && v.endpoint_type == "REGIONAL" && v.use_acm }
  domain   = each.value.domain_name
  statuses = ["ISSUED"]
}

resource "aws_api_gateway_domain_name" "domain_name" {
  for_each                 = local.domain_names
  domain_name              = each.value.domain_name
  certificate_arn          = each.value.endpoint_type == "EDGE" && each.value.use_acm ? (each.value.use_wildcard_domain ? data.aws_acm_certificate.wildcard[each.key].arn : data.aws_acm_certificate.non_wildcard[each.key].arn) : null
  regional_certificate_arn = each.value.endpoint_type == "REGIONAL" && each.value.use_acm ? (each.value.use_wildcard_domain ? data.aws_acm_certificate.regional_wildcard[each.key].arn : data.aws_acm_certificate.regional_non_wildcard[each.key].arn) : null
  endpoint_configuration {
    types = [each.value.endpoint_type]
  }
  tags = local.tags
}

resource "aws_api_gateway_base_path_mapping" "domain_name_mapping" {
  for_each    = local.domain_names
  domain_name = aws_api_gateway_domain_name.domain_name[each.key].id
  api_id      = aws_api_gateway_rest_api.rest_api[split("|", each.key)[0]].id
  stage_name  = aws_api_gateway_stage.stage[split("|", each.key)[0]].stage_name
}
