output "dynamodb_info" {
  value = {
    for k, v in module.dynamodb_table : k => {
      id           = v.dynamodb_table_id
      arn          = v.dynamodb_table_arn
      stream_arn   = v.dynamodb_table_stream_arn
      stream_label = v.dynamodb_table_stream_label
    }
  }
}

output "dynamodb_fullaccess_policy" {
  value = try(aws_iam_policy.dynamodb_fullaccess[0].arn, null)
}