# module "api_gateway" {
#   source                 = "terraform-aws-modules/apigateway-v2/aws"
#   version                = "~> 2.2.2"
#   create                 = var.create
#   name                   = "${module.context.id}-apigateway"
#   description            = "${module.context.id} HTTP API Gateway"
#   protocol_type          = "HTTP"
#   create_api_domain_name = false
#   cors_configuration = {
#     allow_origins = var.allow_origins
#     allow_headers = ["*"]
#     allow_methods = ["*"]
#   }
#   default_route_settings = {
#     detailed_metrics_enabled = false
#     throttling_burst_limit   = 100
#     throttling_rate_limit    = 100
#   }
#   integrations = {
#     "GET /list" = {
#       lambda_arn = try(aws_lambda_function.chat_list_function[0].arn, null)
#     }
#     "POST /auth" = {
#       lambda_arn = try(aws_lambda_function.chat_auth_function[0].arn, null)
#     }
#     "POST /event" = {
#       lambda_arn = try(aws_lambda_function.chat_event_function[0].arn, null)
#     }
#   }
#   tags = local.tags
# }

locals {
  api_paths = {
    "auth" = {
      function_name         = aws_lambda_function.chat_auth_function[0].function_name
      lambda_invocation_arn = aws_lambda_function.chat_auth_function[0].invoke_arn
      http_method           = "POST"
    },
    "event" = {
      function_name         = aws_lambda_function.chat_event_function[0].function_name
      lambda_invocation_arn = aws_lambda_function.chat_event_function[0].invoke_arn
      http_method           = "POST"
    },
    "list" = {
      function_name         = aws_lambda_function.chat_list_function[0].function_name
      lambda_invocation_arn = aws_lambda_function.chat_list_function[0].invoke_arn
      http_method           = "GET"
    }
  }
}

resource "aws_api_gateway_rest_api" "rest_api" {
  count       = var.create ? 1 : 0
  name        = "${module.context.id}-restapi"
  description = "${module.context.id} REST API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.tags
}

resource "aws_api_gateway_resource" "api_resource" {
  for_each    = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  parent_id   = aws_api_gateway_rest_api.rest_api[0].root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "api_method" {
  for_each      = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  resource_id   = aws_api_gateway_resource.api_resource[each.key].id
  http_method   = each.value.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_integration" {
  for_each    = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  http_method = aws_api_gateway_method.api_method[each.key].http_method
  # Lambda function can only be invoked via POST method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda_invocation_arn
}

resource "aws_api_gateway_method_response" "api_method_response" {
  for_each    = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  http_method = aws_api_gateway_method.api_method[each.key].http_method
  status_code = "200"
}

resource "aws_api_gateway_method" "options_method" {
  for_each      = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  resource_id   = aws_api_gateway_resource.api_resource[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  for_each    = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "options_method_response" {
  for_each    = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  for_each    = { for k, v in local.api_paths : k => v if var.create }
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.api_resource[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  status_code = aws_api_gateway_method_response.options_method_response[each.key].status_code

  response_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}


resource "aws_api_gateway_stage" "stage" {
  count         = var.create ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  deployment_id = aws_api_gateway_deployment.api_deployment[0].id
  stage_name    = "Prod"
  tags          = local.tags
}

resource "aws_api_gateway_deployment" "api_deployment" {
  count       = var.create ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  depends_on = [
    aws_api_gateway_integration.api_integration,
    aws_api_gateway_integration_response.options_integration_response
  ]
}

resource "aws_lambda_permission" "lambda_permission" {
  for_each            = { for k, v in local.api_paths : k => v if var.create }
  statement_id_prefix = "AllowExecutionFromRestAPI"
  action              = "lambda:InvokeFunction"
  function_name       = each.value.function_name
  principal           = "apigateway.amazonaws.com"

  #--------------------------------------------------------------------------------
  # Per deployment
  #--------------------------------------------------------------------------------
  # The /*/*  grants access from any method on any resource within the deployment.
  # source_arn = "${aws_api_gateway_deployment.test.execution_arn}/*/*"

  #--------------------------------------------------------------------------------
  # Per API
  #--------------------------------------------------------------------------------
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  # source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*/*"
  #source_arn    = "${aws_api_gateway_rest_api.rest_api[0].execution_arn}/*/${each.value.http_method}/${each.key}"
  source_arn = "${aws_api_gateway_deployment.api_deployment[0].execution_arn}*/*"
}

