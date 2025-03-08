
variable "pinpoint" {
  type = map(object({
    create              = optional(bool)
    gcm_channel_api_key = optional(string)
    email_from_address  = optional(string)
    ses_region          = optional(string)
    base_path_template  = optional(string)
  }))
  default = {}
}

variable "templates_dir" {
  type = string
}