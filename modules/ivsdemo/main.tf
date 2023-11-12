
resource "aws_lambda_layer_version" "ivs_chat_lambda_ref_layer" {
  count               = var.create ? 1 : 0
  layer_name          = "${module.context.id}-dependencies"
  description         = "Dependencies for sam app [ivs-simple-chat-backend]"
  compatible_runtimes = ["nodejs18.x"]
  filename            = "${path.module}/dependencies.zip"
  source_code_hash    = filebase64sha256("${path.module}/dependencies.zip")
}

resource "aws_lambda_function" "chat_auth_function" {
  count            = var.create ? 1 : 0
  function_name    = "${module.context.id}-chatAuth"
  description      = "A function that generates an IVS chat authentication token based on the request parameters."
  handler          = "src/chat-auth.chatAuthHandler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role[0].arn
  layers           = [aws_lambda_layer_version.ivs_chat_lambda_ref_layer[0].arn]
  timeout          = 30
  memory_size      = 128
  filename         = "${path.module}/src.zip"
  source_code_hash = filebase64sha256("${path.module}/src.zip")
}

resource "aws_lambda_function" "chat_event_function" {
  count            = var.create ? 1 : 0
  function_name    = "${module.context.id}-chatEvent"
  description      = "A function that sends an event to a specified IVS chat room"
  handler          = "src/chat-event.chatEventHandler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role[0].arn
  layers           = [aws_lambda_layer_version.ivs_chat_lambda_ref_layer[0].arn]
  timeout          = 30
  memory_size      = 128
  filename         = "${path.module}/src.zip"
  source_code_hash = filebase64sha256("${path.module}/src.zip")
}

resource "aws_lambda_function" "chat_list_function" {
  count            = var.create ? 1 : 0
  function_name    = "${module.context.id}-chatList"
  description      = "A function that returns a list of available chat rooms"
  handler          = "src/chat-list.chatListHandler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role[0].arn
  layers           = [aws_lambda_layer_version.ivs_chat_lambda_ref_layer[0].arn]
  timeout          = 30
  memory_size      = 128
  filename         = "${path.module}/src.zip"
  source_code_hash = filebase64sha256("${path.module}/src.zip")
}

resource "aws_iam_role" "lambda_role" {
  count = var.create ? 1 : 0
  name  = "${module.context.id}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ivschat:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  count  = var.create ? 1 : 0
  name   = "${module.context.id}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.lambda_role[0].id
  policy_arn = aws_iam_policy.lambda_policy[0].arn
}

module "api_gateway" {
  source                 = "terraform-aws-modules/apigateway-v2/aws"
  version                = "~> 2.2.2"
  create                 = var.create
  name                   = "${module.context.id}-apigateway"
  description            = "${module.context.id} HTTP API Gateway"
  protocol_type          = "HTTP"
  create_api_domain_name = false
  cors_configuration = {
    allow_origins = var.allow_origins
    allow_headers = ["*"]
    allow_methods = ["*"]
  }
  default_route_settings = {
    detailed_metrics_enabled = false
    throttling_burst_limit   = 100
    throttling_rate_limit    = 100
  }
  integrations = {
    "GET /list" = {
      lambda_arn = try(aws_lambda_function.chat_list_function[0].arn, null)
    }
    "POST /auth" = {
      lambda_arn = try(aws_lambda_function.chat_auth_function[0].arn, null)
    }
    "POST /event" = {
      lambda_arn = try(aws_lambda_function.chat_event_function[0].arn, null)
    }
  }
  tags = local.tags
}

resource "aws_lambda_permission" "lambda_chat_auth_permission" {
  count         = var.create ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_auth_function[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.apigatewayv2_api_arn}/*/*"
}

resource "aws_lambda_permission" "lambda_chat_event_permission" {
  count         = var.create ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_event_function[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.apigatewayv2_api_arn}/*/*"
}

resource "aws_lambda_permission" "lambda_chat_list_permission" {
  count         = var.create ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_list_function[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.apigatewayv2_api_arn}/*/*"
}
