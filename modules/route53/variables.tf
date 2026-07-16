variable "zones" {
  description = "Zones to manage records in, keyed by zone name. Zones themselves are looked up, never created or destroyed here. Record keys are FQDNs (or FQDN|TYPE when one name carries several types)."
  type = map(object({
    records = optional(map(object({
      type   = string
      ttl    = optional(number, 300)
      values = optional(list(string), [])
      alias = optional(object({
        name                           = optional(string)
        zone_id                        = optional(string)
        application_load_balancer_name = optional(string)
        evaluate_target_health         = optional(bool, false)
      }))
    })), {})
  }))

  validation {
    condition = alltrue(flatten([
      for zone in values(var.zones) : [
        for record in values(zone.records) : record.alias == null || (
          (
            (
              try(record.alias.application_load_balancer_name, null) != null &&
              try(record.alias.name, null) == null &&
              try(record.alias.zone_id, null) == null &&
              try(trimspace(record.alias.application_load_balancer_name), "") != ""
              ) || (
              try(record.alias.application_load_balancer_name, null) == null &&
              try(record.alias.name, null) != null &&
              try(record.alias.zone_id, null) != null &&
              try(trimspace(record.alias.name), "") != "" &&
              try(trimspace(record.alias.zone_id), "") != ""
            )
            ) && (
            try(record.alias.application_load_balancer_name, null) == null ||
            contains(["A", "AAAA"], upper(trimspace(record.type)))
          )
        )
      ]
    ]))
    error_message = "Each alias must set either application_load_balancer_name or both name and zone_id, but not both forms; ALB aliases require record type A or AAAA."
  }
}
