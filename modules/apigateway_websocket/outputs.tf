
output "apigateway_invoke_url" {
  value = {
    for k, v in local.apigateway_map : k => aws_apigatewayv2_stage.stage[k].invoke_url
  }
}