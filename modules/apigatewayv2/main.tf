
# Create API Gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_stage" "lambda" {
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
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


resource "aws_apigatewayv2_integration" "storeimage" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.storeimage.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}


resource "aws_apigatewayv2_route" "storeimage_post" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /storeimage"
  target    = "integrations/${aws_apigatewayv2_integration.storeimage.id}"
}


resource "aws_apigatewayv2_integration" "getallbagids" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.getallbagids.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}


resource "aws_apigatewayv2_route" "getallbagids" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /getallbagids"
  target    = "integrations/${aws_apigatewayv2_integration.getallbagids.id}"
}

resource "aws_apigatewayv2_route" "getallbagids_post" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /getallbagids"
  target    = "integrations/${aws_apigatewayv2_integration.getallbagids.id}"
}


resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = var.api_id

  integration_uri    = var.function_arn
  integration_type   = "AWS_PROXY"
  integration_method = var.http_method
}

resource "aws_apigatewayv2_route" "get_product_route" {
  api_id = var.api_id

  route_key = "${var.http_method} ${var.route}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "get_lambda_api_gw" {
  statement_id  = "AllowLambdaExecutionFromAPIGateway_${var.function_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_arn}/*/*"
}


resource "aws_lambda_permission" "api_gw_storeimage" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.storeimage.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}


resource "aws_lambda_permission" "api_gw_getallbags" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getallbagids.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
