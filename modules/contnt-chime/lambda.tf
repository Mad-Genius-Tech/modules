


data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_cognito_user_pools" "user_pool" {
  name = var.cognito_user_pool_name
}


locals {
  service_name = module.context.id
}

resource "aws_lambda_layer_version" "aws_sdk_chime" {
  layer_name          = "${local.service_name}-aws-sdk-chime"
  description         = "The AWS SDK with support for Amazon Chime SDK messaging features."
  s3_bucket           = "aws-blog-business-productivity-chime-sdk"
  s3_key              = "chat-sdk-demo/aws-sdk-chime-layer.zip"
  compatible_runtimes = ["nodejs18.x"]
}

module "profanity_processor" {
  source         = "terraform-aws-modules/lambda/aws"
  version        = "~> 6.0.0"
  function_name  = "${local.service_name}-profanity-dlp-processor"
  description    = "Lambda that processes Chime channel messages for auto moderation"
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  memory_size    = 128
  timeout        = 30
  create_package = false
  s3_existing_package = {
    bucket = "aws-sdk-chime-channelflowdemo-assets"
    key    = "ChannelFlowProfanityDLPProcessor.zip"
  }
  layers = [
    aws_lambda_layer_version.aws_sdk_chime.arn
  ]
  environment_variables = {
    DOCUMENT_CLASSIFIER_ENDPOINT = "arn:aws:comprehend:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:document-classifier-endpoint/profanityfilter"
  }
  attach_policy            = true
  policy                   = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  attach_policy_statements = true
  policy_statements = {
    comprehend = {
      effect = "Allow",
      actions = [
        "comprehend:BatchDetectDominantLanguage",
        "comprehend:DetectDominantLanguage",
        "comprehend:DetectPiiEntities",
        "comprehend:DetectSentiment",
        "comprehend:ClassifyDocument"
      ],
      resources = ["*"]
    },
    chime_sdk = {
      effect = "Allow",
      actions = [
        "chime:ChannelFlowCallback"
      ],
      resources = [
        "arn:aws:chime:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:app-instance/*"
      ]
    }
  }
}

resource "aws_lambda_permission" "profanity_processor" {
  statement_id   = "AllowExecutionFromChime"
  action         = "lambda:InvokeFunction"
  function_name  = module.profanity_processor.lambda_function_name
  principal      = "messaging.chime.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = "arn:aws:chime:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:app-instance/*"
}

module "presence_processor" {
  source         = "terraform-aws-modules/lambda/aws"
  version        = "~> 6.0.0"
  function_name  = "${local.service_name}-presence-processor"
  description    = "Lambda that processes Chime channel events for custom presence"
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  memory_size    = 128
  timeout        = 30
  create_package = false
  s3_existing_package = {
    bucket = "aws-blog-business-productivity-chime-sdk"
    key    = "presence-demo-assets/custom-presence-channel-processor.zip"
  }
  layers = [
    aws_lambda_layer_version.aws_sdk_chime.arn
  ]
  environment_variables = {
    CHIME_APP_INSTANCE_ADMIN_ID = var.chime_app_instance_admin_id
  }
  attach_policy            = true
  policy                   = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  attach_policy_statements = true
  policy_statements = {
    chime_sdk = {
      effect = "Allow",
      actions = [
        "chime:ChannelFlowCallback",
        "chime:DescribeChannel",
        "chime:UpdateChannel"
      ],
      resources = [
        "arn:aws:chime:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:app-instance/*"
      ]
    }
  }
}

resource "aws_lambda_permission" "presence_processor" {
  statement_id   = "AllowExecutionFromChime"
  action         = "lambda:InvokeFunction"
  function_name  = module.presence_processor.lambda_function_name
  principal      = "messaging.chime.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = "arn:aws:chime:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:app-instance/*"
}

module "chime_app_instance" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 6.0.0"
  function_name           = "${local.service_name}-chime-app-instance"
  runtime                 = "nodejs18.x"
  handler                 = "index.handler"
  timeout                 = 60
  create_package          = false
  local_existing_package  = "src/chime_app_instance/src.zip"
  ignore_source_code_hash = false
  layers = [
    aws_lambda_layer_version.aws_sdk_chime.arn
  ]
  environment_variables = {
    PROCESSOR_LAMBDA_ARN          = module.profanity_processor.lambda_function_arn
    PRESENCE_PROCESSOR_LAMBDA_ARN = module.presence_processor.lambda_function_arn
    LAMBDA_SERVICE_NAME           = local.service_name
  }
  create_role = false
  lambda_role = aws_iam_role.chime_lambda.arn
  depends_on = [
    module.presence_processor,
    module.profanity_processor
  ]
}

resource "aws_lambda_invocation" "chime_app_instance" {
  function_name = module.chime_app_instance.lambda_function_name
  input = jsonencode({
    RequestType = "Create"
  })
  depends_on = [
    module.profanity_processor,
    module.presence_processor,
    module.chime_app_instance
  ]
}

output "chime_app_instance" {
  value = jsondecode(aws_lambda_invocation.chime_app_instance.result)
}

locals {
  chime_app_instance_arn = jsondecode(aws_lambda_invocation.chime_app_instance.result)["AppInstanceArn"]
}

module "chime_app_admin" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 6.0.0"
  function_name           = "${local.service_name}-chime-app-instance-admin"
  runtime                 = "nodejs18.x"
  handler                 = "index.handler"
  timeout                 = 60
  create_package          = false
  local_existing_package  = "src/chime_app_admin/src.zip"
  ignore_source_code_hash = false
  layers = [
    aws_lambda_layer_version.aws_sdk_chime.arn
  ]
  environment_variables = {
    CHIME_APP_INSTANCE_ARN = local.chime_app_instance_arn
  }
  create_role = false
  lambda_role = aws_iam_role.chime_lambda.arn
  depends_on = [
    module.profanity_processor,
    module.presence_processor,
    module.chime_app_instance
  ]
}

resource "aws_lambda_invocation" "chime_app_admin" {
  function_name = module.chime_app_admin.lambda_function_name
  input = jsonencode({
    RequestType = "Create"
  })
  depends_on = [
    module.profanity_processor,
    module.presence_processor,
    module.chime_app_instance,
    module.chime_app_admin
  ]
}

output "chime_app_admin" {
  value = jsondecode(aws_lambda_invocation.chime_app_admin.result)
}

locals {
  chime_app_admin_arn = jsondecode(aws_lambda_invocation.chime_app_admin.result)["AppInstanceAdmin"]["Arn"]
}

module "cognito_signin_hook" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 6.0.0"
  function_name           = "${local.service_name}-cognito-signin-hook"
  runtime                 = "nodejs18.x"
  handler                 = "index.handler"
  memory_size             = 512
  timeout                 = 800
  create_package          = false
  local_existing_package  = "src/cognito_signin/src.zip"
  ignore_source_code_hash = false
  layers = [
    aws_lambda_layer_version.aws_sdk_chime.arn
  ]
  environment_variables = {
    CHIME_APP_INSTANCE_ARN = local.chime_app_instance_arn
  }
  create_role = false
  lambda_role = aws_iam_role.chime_lambda.arn
  depends_on = [
    module.profanity_processor,
    module.presence_processor,
  ]
}

resource "aws_lambda_permission" "cognito_signin" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = module.cognito_signin_hook.lambda_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = data.aws_cognito_user_pools.user_pool.arns[0]
}

# module "preflight_request" {
#   source                 = "terraform-aws-modules/lambda/aws"
#   version                = "~> 6.0.0"
#   function_name          = "${local.service_name}-preflight-request"
#   runtime                = "nodejs18.x"
#   handler                = "index.handler"
#   timeout                = 60
#   local_existing_package = "${path.module}/src/preflight_request/src.zip"
#   layers = [
#     aws_lambda_layer_version.aws_sdk_chime.arn
#   ]
#   create_role = false
#   lambda_role = aws_iam_role.chime_lambda.arn
#   tags        = local.tags
# }

# resource "aws_lambda_permission" "preflight_request" {
#   statement_id  = "AllowExecutionFromCognito"
#   action        = "lambda:InvokeFunction"
#   function_name = module.preflight_request.lambda_function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${ApiGatewayApi}/*/OPTIONS/*"
# }

module "creds_api" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 6.0.0"
  function_name           = "${local.service_name}-creds-api"
  runtime                 = "nodejs18.x"
  handler                 = "index.handler"
  timeout                 = 60
  create_package          = false
  local_existing_package  = "src/creds_api/src.zip"
  ignore_source_code_hash = false
  layers = [
    aws_lambda_layer_version.aws_sdk_chime.arn
  ]
  environment_variables = {
    ChimeAppInstanceArn = local.chime_app_instance_arn
    UserRoleArn         = aws_iam_role.auth_lambda_user.arn
    AnonUserRole        = aws_iam_role.auth_lambda_anonymous.arn
  }
  create_role = false
  lambda_role = aws_iam_role.chime_lambda.arn
}

resource "aws_lambda_permission" "creds_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.creds_api.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/POST/creds"
}
