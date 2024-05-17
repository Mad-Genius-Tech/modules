
output "aurora_mysql_v2_cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = module.aurora.cluster_arn
}

output "aurora_mysql_v2_cluster_id" {
  description = "The RDS Cluster Identifier"
  value       = module.aurora.cluster_id
}

output "aurora_mysql_v2_cluster_resource_id" {
  description = "The RDS Cluster Resource ID"
  value       = module.aurora.cluster_resource_id
}

output "aurora_mysql_v2_cluster_members" {
  description = "List of RDS Instances that are a part of this cluster"
  value       = module.aurora.cluster_members
}

output "aurora_mysql_v2_cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = module.aurora.cluster_endpoint
}

output "aurora_mysql_v2_cluster_reader_endpoint" {
  description = "A read-only endpoint for the cluster, automatically load-balanced across replicas"
  value       = module.aurora.cluster_reader_endpoint
}

output "aurora_mysql_v2_cluster_master_password" {
  description = "The database master password"
  value       = module.aurora.cluster_master_password
  sensitive   = true
}



output "efs_arn" {
  description = "Amazon Resource Name of the file system"
  value       = module.efs.arn
}

output "efs_id" {
  description = "The ID that identifies the file system (e.g., `fs-ccfc0d65`)"
  value       = module.efs.id
}

output "efs_dns_name" {
  description = "The DNS name for the filesystem per [documented convention](http://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html)"
  value       = module.efs.dns_name
}

output "user_data" {
  value = local.user_data
}

output "alb_dns_name" {
  value = module.alb.dns_name
}