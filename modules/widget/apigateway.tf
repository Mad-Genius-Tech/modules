resource "aws_api_gateway_rest_api" "rest_api" {
  name                     = "${module.context.id}-apigateway"
  description              = "API Gateway for ${module.context.id} functions"
  binary_media_types       = ["*/*"]
  minimum_compression_size = 1024
  endpoint_configuration {
    types = var.api_domain_name_endpoint_type == "REGIONAL" ? ["REGIONAL"] : ["EDGE"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = local.tags
}

resource "aws_api_gateway_resource" "prefix" {
  for_each    = local.lambda_map
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = each.value.apigateway_path
}

resource "aws_api_gateway_resource" "compaign_id" {
  for_each    = local.lambda_map
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.prefix[each.key].id
  path_part   = "{campaignId}"
}

resource "aws_api_gateway_method" "campaign_id_get" {
  for_each             = local.lambda_map
  rest_api_id          = aws_api_gateway_rest_api.rest_api.id
  resource_id          = aws_api_gateway_resource.compaign_id[each.key].id
  http_method          = "GET"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.validator.id
  request_parameters = {
    "method.request.path.campaignId" = true
    # "method.request.querystring.platform" = true
  }
}

resource "aws_api_gateway_request_validator" "validator" {
  name                        = "${module.context.id} | Validate request body and querystring parameters"
  rest_api_id                 = aws_api_gateway_rest_api.rest_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_integration" "integration" {
  for_each    = local.lambda_map
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.compaign_id[each.key].id
  http_method = aws_api_gateway_method.campaign_id_get[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda[each.key].lambda_function_invoke_arn
}

# resource "aws_api_gateway_method" "options" {
#   for_each      = local.lambda_map
#   rest_api_id   = aws_api_gateway_rest_api.rest_api.id
#   resource_id   = aws_api_gateway_resource.compaign_id[each.key].id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "cors" {
#   for_each    = local.lambda_map
#   rest_api_id = aws_api_gateway_rest_api.rest_api.id
#   resource_id = aws_api_gateway_method.options[each.key].resource_id
#   http_method = aws_api_gateway_method.options[each.key].http_method
#   type        = "MOCK"

#   request_templates = {
#     "application/json" = "{\"statusCode\": 200}"
#   }
# }

# resource "aws_api_gateway_method_response" "cors_response" {
#   for_each    = local.lambda_map
#   rest_api_id = aws_api_gateway_rest_api.rest_api.id
#   resource_id = aws_api_gateway_method.options[each.key].resource_id
#   http_method = aws_api_gateway_method.options[each.key].http_method
#   status_code = "200"

#   response_models = {
#     "application/json" = "Empty"
#   }
# }

# resource "aws_api_gateway_integration_response" "cors_integration" {
#   for_each    = local.lambda_map
#   rest_api_id = aws_api_gateway_rest_api.rest_api.id
#   resource_id = aws_api_gateway_method.options[each.key].resource_id
#   http_method = aws_api_gateway_method.options[each.key].http_method
#   status_code = "200"

#   response_templates = {
#     "application/json" = ""
#   }

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = "'*'",
#     "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
#     "method.response.header.Access-Control-Allow-Origin"  = "'*'"
#   }
# }

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "prod"

  dynamic "access_log_settings" {
    for_each = var.create_apigateway_log_group ? [1] : []

    content {
      destination_arn = aws_cloudwatch_log_group.apigateway_log_group[0].arn
      format          = replace(var.apigateway_log_format, "\n", "")
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.apigateway_log_group,
    aws_api_gateway_account.apigateway_cloudwatch_logs
  ]
  tags = local.tags
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  depends_on = [
    aws_api_gateway_rest_api.rest_api,
    aws_api_gateway_resource.prefix,
    aws_api_gateway_resource.compaign_id,
    aws_api_gateway_method.campaign_id_get,
    aws_api_gateway_integration.integration,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.rest_api,
      aws_api_gateway_resource.prefix,
      aws_api_gateway_resource.compaign_id,
      aws_api_gateway_method.campaign_id_get,
      aws_api_gateway_integration.integration,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "api_gateway" {
  for_each      = local.lambda_map
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[each.key].lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "apigateway_log_group" {
  count             = var.create_apigateway_log_group ? 1 : 0
  name              = "${module.context.id}-apigateway"
  retention_in_days = var.log_group_retention_in_days
  tags              = local.tags
}

resource "aws_api_gateway_account" "apigateway_cloudwatch_logs" {
  count               = var.create_apigateway_log_group ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_logs[0].arn
}

resource "aws_iam_role" "apigateway_cloudwatch_logs" {
  count = var.create_apigateway_log_group ? 1 : 0
  name  = "${module.context.id}-apigateway"

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
  count  = var.create_apigateway_log_group ? 1 : 0
  name   = "${module.context.id}-apigateway"
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


#############################
# API Gateway Domain Name
#############################
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_acm_certificate" "wildcard" {
  count    = var.api_domain_name_endpoint_type == "EDGE" && var.use_wildcard_domain ? 1 : 0
  domain   = length(split(".", var.api_domain_name)) > 2 ? join(".", slice(split(".", var.api_domain_name), 1, length(split(".", var.api_domain_name)))) : var.api_domain_name
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

data "aws_acm_certificate" "non_wildcard" {
  count    = var.api_domain_name_endpoint_type == "EDGE" && !var.use_wildcard_domain ? 1 : 0
  domain   = var.api_domain_name
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

data "aws_acm_certificate" "regional_wildcard" {
  count    = var.api_domain_name_endpoint_type == "REGIONAL" && var.use_wildcard_domain ? 1 : 0
  domain   = length(split(".", var.api_domain_name)) > 2 ? join(".", slice(split(".", var.api_domain_name), 1, length(split(".", var.api_domain_name)))) : var.api_domain_name
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "regional_non_wildcard" {
  count    = var.api_domain_name_endpoint_type == "REGIONAL" && !var.use_wildcard_domain ? 1 : 0
  domain   = var.api_domain_name
  statuses = ["ISSUED"]
}

resource "aws_api_gateway_domain_name" "domain_name" {
  domain_name              = var.api_domain_name
  certificate_arn          = var.api_domain_name_endpoint_type == "EDGE" ? (var.use_wildcard_domain ? data.aws_acm_certificate.wildcard[0].arn : data.aws_acm_certificate.non_wildcard[0].arn) : null
  regional_certificate_arn = var.api_domain_name_endpoint_type == "REGIONAL" ? (var.use_wildcard_domain ? data.aws_acm_certificate.regional_wildcard[0].arn : data.aws_acm_certificate.regional_non_wildcard[0].arn) : null
  endpoint_configuration {
    types = [var.api_domain_name_endpoint_type]
  }
  tags = local.tags
}

resource "aws_api_gateway_base_path_mapping" "domain_name_mapping" {
  domain_name = aws_api_gateway_domain_name.domain_name.id
  api_id      = aws_api_gateway_rest_api.rest_api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
}
