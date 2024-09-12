output "rds_info" {
  value = {
    for k, v in module.rds : k => {
      db_instance_identifier             = v.db_instance_identifier,
      db_instance_master_user_secret_arn = v.db_instance_master_user_secret_arn,
      db_instance_address                = v.db_instance_address,
      db_instance_arn                    = v.db_instance_arn,
      db_instance_endpoint               = v.db_instance_endpoint,
      db_instance_identifier             = v.db_instance_identifier,
      db_instance_port                   = v.db_instance_port,
      db_instance_name                   = v.db_instance_name,
      db_security_group_id               = module.rds_sg[k].security_group_id,
      db_secret_path                     = aws_secretsmanager_secret.secret[k].name
    }
  }
}

output "rds_proxy" {
  value = {
    for k, v in module.rds : k => {
      proxy_endpoint        = module.rds_proxy[k].proxy_endpoint
      proxy_target_endpoint = module.rds_proxy[k].proxy_target_endpoint
      db_proxy_endpoints    = module.rds_proxy[k].db_proxy_endpoints
    } if local.rds_map[k].enable_proxy
  }
}
