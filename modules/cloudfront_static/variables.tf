variable "wildcard_domain" {
  type    = bool
  default = true
}

variable "domain_names" {
  type = list(string)
}

variable "static_s3_bucket" {
  type = string
}
