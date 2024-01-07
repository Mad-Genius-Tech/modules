output "api_execution_url" {
  value = var.create ? "https://${aws_api_gateway_rest_api.rest_api[0].id}.execute-api.${data.aws_region.current.name}.amazonaws.com/Prod" : null
}