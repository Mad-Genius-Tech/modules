variable "zones" {
  description = "Zones to manage records in, keyed by zone name. Zones themselves are looked up, never created or destroyed here. Record keys are FQDNs (or FQDN|TYPE when one name carries several types)."
  type = map(object({
    records = optional(map(object({
      type   = string
      ttl    = optional(number, 300)
      values = optional(list(string), [])
      alias = optional(object({
        name                   = string
        zone_id                = string
        evaluate_target_health = optional(bool, false)
      }))
    })), {})
  }))
}
