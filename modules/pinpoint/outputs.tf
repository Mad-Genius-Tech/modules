output "app" {
  value = {
    for k, v in aws_pinpoint_app.app : k => {
      "id"  = v.id
      "arn" = v.arn
    }
  }
}