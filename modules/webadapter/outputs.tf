output "lambda_function_arn" {
  value = module.webadapter.lambda_function_arn
}

output "lambda_function_invoke_arn" {
  value = module.webadapter.lambda_function_invoke_arn
}

output "lambda_function_name" {
  value = module.webadapter.lambda_function_name
}

output "lambda_function_domain_name" {
  value = trimsuffix(trimprefix(module.webadapter.lambda_function_url, "https://"), "/")
}