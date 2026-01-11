output "efs_ids" {
  value = { for k, v in module.efs : k => {
    id            = v.id
    arn           = v.arn
    dns_name      = v.dns_name
    access_points = v.access_points
    }
  }
}

output "single_az" {
  value = local.single_az
}

output "private_subnet_ids" {
  value = var.private_subnet_ids
}