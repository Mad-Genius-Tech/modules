

resource "aws_service_discovery_private_dns_namespace" "service_discovery_dns" {
  count = var.service_discovery_dns_name != "" ? 1 : 0
  name  = var.service_discovery_dns_name
  vpc   = var.vpc_id
  tags  = local.tags
}

resource "aws_service_discovery_service" "service_discovery" {
  for_each = { for k, v in local.ecs_map : k => v if v.create && v.enable_service_discovery }
  name     = each.key
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.service_discovery_dns[0].id
    dns_records {
      type = "A"
      ttl  = 10
    }
  }
}