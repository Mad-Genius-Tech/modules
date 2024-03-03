resource "aws_elasticache_replication_group" "elasticache" {
  replication_group_id       = "${module.context.id}-redis"
  description                = "Redis replication group for ${module.context.id}"
  engine                     = "redis"
  node_type                  = "cache.t4g.micro"
  port                       = 6379
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  num_cache_clusters         = 1
  parameter_group_name       = "default.redis7"
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group.name
  security_group_ids         = [module.redis_sg.security_group_id]
  tags                       = local.tags
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  name        = "${module.context.id}-redis"
  description = "Elasticache subnet group for ${module.context.id}"
  subnet_ids  = var.private_subnet_ids
  tags        = local.tags
}

module "redis_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.1.1"
  name        = "${module.context.id}-redis"
  description = "ElastiCache ${module.context.id} Security group"
  vpc_id      = var.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr_block
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = local.tags
}
