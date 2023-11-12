output "aws_region" {
  value = data.aws_region.current
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available
}

output "vpc_name" {
  value = module.vpc.name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets_cidr_blocks" {
  value = module.vpc.public_subnets_cidr_blocks
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "vgw_id" {
  value = module.vpc.vgw_id
}
