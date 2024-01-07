resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "${local.service_name}-api"
  description = "Amazon Chime SDK Chat Demo APIs"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "creds_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "creds"
}

resource "aws_api_gateway_method" "creds_post" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.creds_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "creds_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.creds_resource.id
  http_method             = aws_api_gateway_method.creds_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.creds_api.lambda_function_invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method_response" "creds_post_200_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.creds_resource.id
  http_method = aws_api_gateway_method.creds_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_method" "creds_options" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.creds_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# resource "aws_api_gateway_integration" "creds_options_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.rest_api.id
#   resource_id             = aws_api_gateway_resource.creds_resource.id
#   http_method             = aws_api_gateway_method.creds_options.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.preflight_request_lambda_arn}/invocations"
#   passthrough_behavior    = "WHEN_NO_MATCH"
#   content_handling        = "CONVERT_TO_TEXT"
# }

# resource "aws_api_gateway_method_response" "creds_options_200_response" {
#   rest_api_id = aws_api_gateway_rest_api.rest_api.id
#   resource_id = aws_api_gateway_resource.creds_resource.id
#   http_method = aws_api_gateway_method.creds_options.http_method
#   status_code = "200"
# }

resource "aws_api_gateway_integration" "creds_options_integration" {
  rest_api_id          = aws_api_gateway_rest_api.rest_api.id
  resource_id          = aws_api_gateway_resource.creds_resource.id
  http_method          = aws_api_gateway_method.creds_options.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
}

resource "aws_api_gateway_method_response" "creds_options_200_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.creds_resource.id
  http_method = aws_api_gateway_method.creds_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "creds_options_200_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.creds_resource.id
  http_method = aws_api_gateway_method.creds_options.http_method
  status_code = aws_api_gateway_method_response.creds_options_200_response.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}