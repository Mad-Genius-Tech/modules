output "agent_runtime_id" {
  value = join("", aws_bedrockagentcore_agent_runtime.agentcore[*].agent_runtime_id)
}

output "agent_runtime_name" {
  value = join("", aws_bedrockagentcore_agent_runtime.agentcore[*].agent_runtime_name)
}

output "agent_runtime_arn" {
  value = join("", aws_bedrockagentcore_agent_runtime.agentcore[*].agent_runtime_arn)
}

output "agent_runtime_role_arn" {
  value = join("", aws_iam_role.agentcore[*].arn)
}

output "conversations_table_arn" {
  value = join("", aws_dynamodb_table.conversations[*].arn)
}

output "conversations_table_name" {
  value = join("", aws_dynamodb_table.conversations[*].name)
}

output "runtime_environment" {
  value = local.runtime_environment_variables
}

output "bedrock_inference_profile_arn" {
  value = join("", aws_bedrock_inference_profile.inference_profile[*].arn)
}

output "bedrock_inference_profile_id" {
  value = join("", aws_bedrock_inference_profile.inference_profile[*].id)
}

output "frontend_policy_arn" {
  value = join("", aws_iam_policy.frontend[*].arn)
}
