output "record_fqdns" {
  value = { for k, r in aws_route53_record.record : k => r.fqdn }
}
