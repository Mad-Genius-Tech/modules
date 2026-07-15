data "aws_route53_zone" "zone" {
  for_each = var.zones
  name     = each.key
}

locals {
  # Flatten to one map entry per record; key format "<zone>|<record-key>",
  # record-key = FQDN or "FQDN|TYPE".
  records = merge([
    for zone_name, zone in var.zones : {
      for record_key, record in zone.records :
      "${zone_name}|${record_key}" => merge(record, {
        zone = zone_name
        name = split("|", record_key)[0]
        type = length(split("|", record_key)) > 1 ? split("|", record_key)[1] : record.type
      })
    }
  ]...)

  application_load_balancer_aliases = {
    for record_key, record in local.records : record_key => try(record.alias.application_load_balancer_name, null)
    if record.alias != null && try(record.alias.application_load_balancer_name, null) != null
  }
}

data "aws_lb" "alias" {
  for_each = local.application_load_balancer_aliases
  name     = each.value
}

resource "aws_route53_record" "record" {
  for_each = local.records
  zone_id  = data.aws_route53_zone.zone[each.value.zone].zone_id
  name     = each.value.name
  type     = each.value.type
  ttl      = each.value.alias == null ? each.value.ttl : null
  records  = each.value.alias == null ? each.value.values : null

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name = alias.value.application_load_balancer_name != null ? (
        "dualstack.${data.aws_lb.alias[each.key].dns_name}"
      ) : alias.value.name
      zone_id = alias.value.application_load_balancer_name != null ? (
        data.aws_lb.alias[each.key].zone_id
      ) : alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
}
