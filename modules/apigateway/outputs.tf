output "invoke_url" {
  value = { for k, v in aws_api_gateway_stage.stage : k => v.invoke_url }
}

output "test_invoke_url" {
  value = { for k, v in aws_api_gateway_stage.test : k => v.invoke_url }
}

output "stage_arn" {
  value = { for k, v in aws_api_gateway_stage.stage : k => v.arn }
}

output "test_stage_arn" {
  value = { for k, v in aws_api_gateway_stage.test : k => v.arn }
}

output "regional_domain_name" {
  value = { for k, v in aws_api_gateway_domain_name.domain_name : k => v.regional_domain_name }
}

output "global_domain_name" {
  value = { for k, v in aws_api_gateway_domain_name.domain_name : k => v.cloudfront_domain_name }
}

output "api_key" {
  value     = { for k, v in aws_api_gateway_api_key.api_key : k => v.value }
  sensitive = true
}