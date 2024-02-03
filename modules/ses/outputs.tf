output "contact_list_id" {
  value = try(aws_sesv2_contact_list.contact_list[0].id, "")
}

output "contact_list_last_updated_timestamp" {
  value = try(aws_sesv2_contact_list.contact_list[0].last_updated_timestamp, "")
}

output "contact_export_function_url" {
  value = try(module.contact_export.lambda_function_url, "")
}