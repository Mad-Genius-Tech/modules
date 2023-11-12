output "regional_acm_certificate_arn" {
  value = { for k, v in module.regional_acm : k => v.acm_certificate_arn }
}

output "regional_validation_domains" {
  value = { for k, v in module.regional_acm : k => v.validation_domains }
}

output "global_acm_certificate_arn" {
  value = { for k, v in module.global_acm : k => v.acm_certificate_arn }
}

output "global_validation_domains" {
  value = { for k, v in module.global_acm : k => v.validation_domains }
}