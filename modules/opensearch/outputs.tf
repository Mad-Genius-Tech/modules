output "opensearch_info" {
  value = {
    for k, v in aws_opensearch_domain.opensearch : k => {
      arn                = v.arn
      id                 = v.id
      domain_id          = v.domain_id
      domain_name        = v.domain_name
      endpoint           = v.endpoint
      dashboard_endpoint = v.dashboard_endpoint
      vpc_id             = v.vpc_options[0].vpc_id
      secret_path        = aws_secretsmanager_secret.secret[k].name
    }
  }
}
