
output "redis_info" {
  value = {
    for k, v in aws_elasticache_replication_group.redis : k => {
      id                              = v.id
      arn                             = v.arn
      primary_endpoint_address        = v.primary_endpoint_address
      reader_endpoint_address         = v.reader_endpoint_address
      member_clusters                 = v.member_clusters
      aws_elasticache_parameter_group = v.engine == "redis" ? aws_elasticache_parameter_group.parameter_group[k].id : aws_elasticache_parameter_group.valkey_parameter_group[k].name
      aws_elasticache_subnet_group    = aws_elasticache_subnet_group.subnet_group[k].name
      security_group_id               = module.redis_sg[k].security_group_id
    }
  }
}


