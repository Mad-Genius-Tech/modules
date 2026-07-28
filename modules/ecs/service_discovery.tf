

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

# A static/private host can resolve to a stable service name without owning an
# ECS task or a second Cloud Map A record. The dependency serializes a same-name
# cutover: update or remove ECS service registries first, remove the old record,
# then create the CNAME alias.
resource "aws_service_discovery_service" "cname_alias" {
  for_each = var.service_discovery_cname_aliases
  name     = each.key

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.service_discovery_dns[0].id
    routing_policy = "WEIGHTED"

    dns_records {
      type = "CNAME"
      ttl  = 10
    }
  }

  lifecycle {
    precondition {
      condition = !contains([
        for name, service in local.ecs_map : name
        if service.create && service.enable_service_discovery
      ], each.key)
      error_message = "A CNAME alias cannot share a name with an ECS service-discovery registration. Disable or remove the ECS registration before creating the alias."
    }
  }

  depends_on = [
    module.ecs_service,
    module.ecs_service_multiples,
    aws_service_discovery_service.service_discovery,
  ]
}

resource "aws_service_discovery_instance" "cname_alias" {
  for_each    = var.service_discovery_cname_aliases
  instance_id = "alias-${each.key}"
  service_id  = aws_service_discovery_service.cname_alias[each.key].id

  attributes = {
    AWS_INSTANCE_CNAME = each.value
  }
}
