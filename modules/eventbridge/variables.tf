
variable "eventbus" {
  type = map(object({
    create   = optional(bool)
    bus_name = optional(string)
  }))
}
