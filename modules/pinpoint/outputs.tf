output "app" {
  value = {
    for k, v in aws_pinpoint_app.app : k => {
      "id"  = v.id
      "arn" = v.arn
    }
  }
}

output "email_templates" {
  description = "ARNs of the created email templates"
  value = {
    for k, v in aws_pinpoint_email_template.templates : k => {
      "name" = v.name
      "arn"  = v.arn
    }
  }
}
