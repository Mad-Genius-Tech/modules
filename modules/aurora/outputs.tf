output "aurora_info" {
  value = {
    for k, v in module.aurora_postgresql_v2 : k => {
      cluster_arn                = v.cluster_arn
      cluster_id                 = v.cluster_id
      cluster_endpoint           = v.cluster_endpoint
      cluster_reader_endpoint    = v.cluster_reader_endpoint
      cluster_resource_id        = v.cluster_resource_id
      security_group_id          = v.security_group_id
      cluster_master_user_secret = v.cluster_master_user_secret
      secret_path                = aws_secretsmanager_secret.secret[k].name
    }
  }
}
